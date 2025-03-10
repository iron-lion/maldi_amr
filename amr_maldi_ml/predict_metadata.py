"""Predict metadata columns.

The purpose of this experiment is to investigate whether we are able to
predict metadata based on the spectrum itself.
"""

import argparse
import collections
import dotenv
import json
import logging
import pathlib
import os
import warnings

import numpy as np

from maldi_learn.driams import DRIAMSDatasetExplorer
from maldi_learn.driams import load_driams_dataset

from utilities import generate_output_filename

from sklearn.exceptions import ConvergenceWarning
from sklearn.linear_model import LogisticRegressionCV
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import recall_score

dotenv.load_dotenv()
DRIAMS_ROOT = os.getenv('DRIAMS_ROOT')

# These parameters should remain fixed for this particular
# experiment. We always train on the same data set, using
# *all* available years.
site = 'DRIAMS-A'
years = ['2015', '2016', '2017', '2018']


def _run_experiment(
    root,
    fingerprints,
    species,
    antibiotic,
    column,
    exclude,
    seed,
    output_path,
    force,
    model,
    n_jobs=-1
):
    """Run a single experiment for a given species--antibiotic combination."""
    driams_dataset = load_driams_dataset(
            root,
            site,
            years,
            species=species,
            antibiotics=antibiotic,  # Only a single one for this run
            handle_missing_resistance_measurements='remove_if_all_missing',
            id_suffix='strat',
            spectra_type='binned_6000_warped',
    )

    logging.info(f'Loaded data set for {species} and {antibiotic}')

    # Create feature matrix from the binned spectra. We only need to
    # consider the second column of each spectrum for this.
    X = np.asarray([spectrum.intensities for spectrum in driams_dataset.X])

    logging.info('Finished vectorisation')

    y = driams_dataset.y[column].values

    if exclude:
        logging.info(f'Excluding value "{exclude}" from column')

        indices = y != exclude
        X = X[indices]
        y = y[indices]

    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(y)

    clf = LogisticRegressionCV(
        scoring='accuracy',
        cv=5,
        multi_class='ovr',
        random_state=seed
    )

    with warnings.catch_warnings():
        warnings.filterwarnings('ignore', category=ConvergenceWarning)
        clf.fit(X, y)

    logging.info('Finished training and hyperparameter selection')

    n_splits = 5
    cv = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=seed)

    # Store scores calculated during the cross-validation. This is
    # slightly more tedious than doing it via `cross_validate` but
    # we need a confusion matrix as well.
    scores = collections.defaultdict(list)
    cm = None

    for train_index, test_index in cv.split(X, y):
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]

        clf.fit(X_train, y_train)

        y_pred_train = clf.predict(X_train)
        y_pred_test = clf.predict(X_test)

        scores['train_accuracy'].append(
            accuracy_score(y_train, y_pred_train)
        )
        scores['test_accuracy'].append(
            accuracy_score(y_test, y_pred_test)
        )

        for i in range(len(label_encoder.classes_)):
            class_name = label_encoder.classes_[i]
            name = f'recall_class_{class_name}'
            scores[name].append(
                recall_score(
                    y_test,
                    y_pred_test,
                    labels=[i],
                    average='weighted',
                    zero_division=0,
                )
            )

        if cm is None:
            cm = confusion_matrix(
                    label_encoder.inverse_transform(y_test),
                    label_encoder.inverse_transform(y_pred_test),
                    labels=label_encoder.classes_
            )
        else:
            cm += confusion_matrix(
                    label_encoder.inverse_transform(y_test),
                    label_encoder.inverse_transform(y_pred_test),
                    labels=label_encoder.classes_
            )

    cm = cm / n_splits

    logging.info('Finished cross-validated predictions')

    # Prepare the output dictionary containing all information to
    # reproduce the experiment.
    output = {
        'site': site,
        'seed': seed,
        'model': model,
        'antibiotic': antibiotic,
        'species': species,
        'column': column,
        'years': years,
        'n_samples': len(X),
        'bincount': np.bincount(y).tolist(),
        'classes': label_encoder.classes_.tolist(),
    }

    if exclude:
        suffix = f'{column}_no_{exclude}'
    else:
        suffix = column

    output_filename = generate_output_filename(
        output_path,
        output,
        suffix=suffix
    )

    # Add fingerprint information about the metadata files to make sure
    # that the experiment is reproducible.
    output['metadata_versions'] = fingerprints

    # Only write if we either are running in `force` mode, or the
    # file does not yet exist.
    if not os.path.exists(output_filename) or force:

        output.update(scores)
        output['confusion_matrix'] = cm.ravel().tolist() 

        logging.info(f'Saving {os.path.basename(output_filename)}')

        with open(output_filename, 'w') as f:
            json.dump(output, f, indent=4)
    else:
        logging.warning(
            f'Skipping {output_filename} because it already exists.'
        )


if __name__ == '__main__':

    # Basic log configuration to ensure that we see where the process
    # spends most of its time.
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(message)s'
    )

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-a', '--antibiotic',
        default='Ceftriaxone',
        type=str,
        help='Antibiotic for which to run the experiment'
    )

    parser.add_argument(
        '-s', '--species',
        default='Escherichia coli',
        type=str,
        help='Species for which to run the experiment'
    )

    parser.add_argument(
        '-S', '--seed',
        type=int,
        default=123,
        help='Random seed to use for the experiment'
    )

    parser.add_argument(
        '-m', '--model',
        default='lr',
        help='Selects model to use for subsequent training'
    )

    parser.add_argument(
        '-c', '--column',
        type=str,
        default='workstation',
        help='Selects metadata column to predict'
    )

    parser.add_argument(
        '-e', '--exclude',
        type=str,
        help='Selects optional value to exclude from column'
    )

    name = 'predict_metadata'

    parser.add_argument(
        '-o', '--output',
        default=pathlib.Path(__file__).resolve().parent.parent / 'results'
                                                               / name,
        type=str,
        help='Output path for storing the results.'
    )

    parser.add_argument(
        '-f', '--force',
        action='store_true',
        help='If set, overwrites all files. Else, skips existing files.'
    )

    args = parser.parse_args()

    # Create the output directory for storing all results of the
    # individual combinations.
    os.makedirs(args.output, exist_ok=True)

    logging.info(f'Site: {site}')
    logging.info(f'Years: {years}')
    logging.info(f'Seed: {args.seed}')
    logging.info(f'Column: {args.column}')

    explorer = DRIAMSDatasetExplorer(DRIAMS_ROOT)
    metadata_fingerprints = explorer.metadata_fingerprints(site)

    # How many jobs to use to run this experiment. Should be made
    # configurable ideally.
    n_jobs = 24

    _run_experiment(
        explorer.root,
        metadata_fingerprints,
        args.species,
        args.antibiotic,
        args.column,
        args.exclude,
        args.seed,
        args.output,
        args.force,
        args.model,
        n_jobs
    )
