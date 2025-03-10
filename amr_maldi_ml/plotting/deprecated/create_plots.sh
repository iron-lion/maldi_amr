

# ------------
# Figure 2: barplot and vmeplot
# ------------
#antibiotic_list_small=("Ciprofloxacin,Amoxicillin-Clavulanic acid,Ceftriaxone,Oxacillin,Tigecycline,Colistin,Fluconazole")
#echo "$antibiotic_list_small"
#
#python plot_fig2_baseline_barplot.py --antibiotic "$antibiotic_list_small" \
#      --outfile plots/fig2/fig2_barplot_few
#python plot_fig2_baseline_vmeplots.py --antibiotic "$antibiotic_list_small" \
#      --outfile plots/fig2/fig2_vmeplots_few
#
#python plot_fig2_baseline_barplot.py --antibiotic None \
#     --outfile plots/fig2/fig2_barplot_all
#python plot_fig2_baseline_vmeplots.py --antibiotic None \
#     --outfile plots/fig2/fig2_vmeplots_all


# -------------
# Figure 3: Ensemble training vs. species training curves
# -------------
#python plot_fig3_ensemble_curves.py ../results/fig3_ensemble \
#        --outdir ./plots/fig3


# ------------
# Figure 4: AUC curves per species and antibiotic
# ------------
#for model in "lr" "svm-rbf" "svm-linear" "lightgbm" "rf"; do
#  python plot_fig4_curves_per_species_and_antibiotic_2panels.py \
#    --species "Escherichia coli" \
#    --antibiotic \
#      "Ciprofloxacin,Ceftriaxone,Cefepime,Piperacillin-Tazobactam,Tobramycin" \
#    --model $model \
#    --outfile "plots/fig4/fig4_Ecoli_$model"
#done
#
#for model in "lr" "svm-rbf" "svm-linear" "lightgbm" "rf"; do
#  python plot_fig4_curves_per_species_and_antibiotic_2panels.py \
#    --species "Staphylococcus aureus" \
#    --antibiotic "Ciprofloxacin,Fusidic acid,Oxacillin,Penicillin" \
#    --model $model \
#    --outfile "plots/fig4/fig4_Saureus_$model"
#done
#
#for model in "lr" "svm-rbf" "svm-linear" "lightgbm" "rf"; do
#  python plot_fig4_curves_per_species_and_antibiotic_2panels.py \
#    --species "Klebsiella pneumoniae" \
#    --antibiotic \
#      "Ciprofloxacin,Ceftriaxone,Cefepime,Meropenem,Tobramycin" \
#    --model $model \
#    --outfile "plots/fig4/fig4_Kpneu_$model"
#done


# ------------
# Figure 5: Validation comparison plots
# ------------

#for model in "lr" "svm-rbf" "svm-linear" "lightgbm" "rf"; do
#  for metric in "auroc" "auprc"; do
#    python plot_fig5_validation.py \
#      --model $model \
#      --metric $metric \
#      --outfile "plots/fig5/fig5_${model}_${metric}"
#  done
#done

# ------------
# Figure 5: Validation prevalence heatmaps
# ------------

#for antibiotic in "Ciprofloxacin" "Ceftriaxone" "Cefepime" "Amoxicillin-Clavulanic acid" "Piperacillin-Tazobactam" "Oxacillin" "Penicillin"; do
#  python plot_fig5_site_prevalences.py \
#    --antibiotic "$antibiotic" \
#    --outfile "plots/fig5/fig5_prevalence_$antibiotic"
#done

# ------------
# Calibration plots 
# ------------

#for metric in "auroc" "auprc" "accuracy" "specificity" "sensitivity"; do
#  python plot_calibration_curves.py -m "$metric" ../results/calibrated_classifiers \
#    --outdir plots/calibration
#done

    
# ------------
# Sliding Window Temporal Validation 
# ------------

for metric in "auroc" "auprc" "train_sample_size"; do
    for clf in "lr" "lightgbm"; do
#for metric in "auroc"; do
#    for clf in "lr" "lightgbm"; do
        python plot_sliding_window_validation.py -d train_from -m $metric ../results/sliding_window_validation/${clf}/*TimeDelta*[0-9].json 
        python plot_sliding_window_validation.py -d train_from -m $metric -s cumulative ../results/sliding_window_validation/${clf}/*TimeDelta*cumulative.json 
    done
done
