#!/usr/bin/env python
# coding: utf-8

# In[1]:


import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sn
# import pytesseract as tb

import csv

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
pd.options.display.float_format = '{:,.2f}'.format
sn.set_style('whitegrid')
# get_ipython().run_line_magic('matplotlib', 'inline')  # notebook-only magic

# Shim so notebook `display(...)` calls work when run as a plain script.
try:
    display
except NameError:
    display = print

pathh = "./data/intermediate/spain/descriptive_stats/"


# In[2]:


def format_log_files(files,path,filame_target,keywords_start=["tab","tabstat"],keywords_end=["N","Total"],
                     loop_tab=False,descriptive_var_list=None,debug=False):
    table_no = 1
    if loop_tab:
        index_key = 0
    else:
        index_key = 1
    for file in files:
        print(file)
        res_spa_file = path+file
        with open(res_spa_file) as file:
            reading = 0
            type_i = 0
            lines = file.read().splitlines()
            output = []
            for line in lines:
                line = line.replace('|','')
                words = line.split()
                if debug:
                    print(words)
                if len(words)>=1 and words[index_key] in keywords_start :
                    # print()
                    reading = 1
                elif len(words)>2 and words[0] not in ['.','opened','','closed'] and reading:
                    if descriptive_var_list!=None:
                        if words[0] in descriptive_var_list:
                            output = []
                            row_length = len(words)
                            # print(row_length)
                    filterr = 1 - np.array([i.replace(",","").replace(".","").isnumeric() for i in words])
        
                    if descriptive_var_list!=None:
                        if words[0] in descriptive_var_list:
                            words_filtered = words                       
                        elif filterr.sum()==0 or np.sum(1-filterr)==0:
                            words_filtered = words
                        else:                    
                            var = " ".join(words[:filterr.sum()])                
                            words_filtered = [var,] + [i.replace(",","") for i in words[filterr.sum():]]

                    else:
                        if filterr.sum()==0 or np.sum(1-filterr)==0:
                            words_filtered = words
                        else:                    
                            var = " ".join(words[:filterr.sum()])                
                            words_filtered = [var,] + [i.replace(",","") for i in words[filterr.sum():]]
                    
                    if descriptive_var_list!=None:
                        if len(words_filtered) == row_length-1:
                            words_filtered = [' ',] + words_filtered
                    output.append(words_filtered)
                    if words[0] in keywords_end:
                        # print(output, table_no)
                        reading=0
                        with open(path+filame_target+"{}.csv".format(table_no), 'w',newline='') as csvfile:
                            w = csv.writer(csvfile)
                            w.writerows(output)
                            table_no += 1
                            output = []
    print('Done!')


# <a id="index"></a>
# 
# # Index
# 
# - [Duration of unstable spells (tab:desstats_dur)](#dur)
# - [Main descriptive stats – individual level (tab:desstats_2+spell)](#main)
# - [Education breakdown (tab:desstats_2+spell)](#educ)
# 

# In[3]:


res_ger_file = r'./data/intermediate/germany/05_descriptives.log'


# In[4]:


with open(res_ger_file) as file:
    reading = 0
    type_i = 0
    table_no = 1
    row_length = None
    lines = file.read().splitlines()
    output = []
    descriptive_var_list = ['attached','unattached','max_TC_sample','Industry','educ2','state_detail','state_c',"Employment"]

    for line in lines:
        line = line.replace('|','')
        words = line.split()

        if len(words) > 1 and (words[1] == "tab" or words[1] == "tabstat") and words[0] != ">":
            reading = 1
            row_length = None

        elif len(words) > 2 and words[0] not in ['.','opened','','closed'] and words[1] != '' and reading:
            if words[0] in descriptive_var_list:
                output = []
                if words[0] == "Employment":
                    man_i = words.pop(1)
                    words[0] = words[0] + " " + man_i
                    descriptive_var_list[-1] = words[0]
                row_length = len(words)

            filterr = 1 - np.array([i.replace(",","").replace(".","").isnumeric() for i in words])

            if words[0] in descriptive_var_list:
                words_filtered = words
            elif filterr.sum() == 0 or np.sum(1 - filterr) == 0:
                words_filtered = words
            else:
                var = " ".join(words[:filterr.sum()])
                words_filtered = [var] + [i.replace(",","") for i in words[filterr.sum():]]
                if words[0] == "Manufacturing":
                    man_i = words_filtered.pop(1)
                    words_filtered[0] = words_filtered[0] + " " + man_i

            if row_length is not None and len(words_filtered) == row_length - 1:
                words_filtered = [' '] + words_filtered

            output.append(words_filtered)

            if words[0] == 'N' or words[0] == 'Total':
                reading = 0
                with open("./output/intermediate/descriptive_stats_ger_tab{}.csv".format(table_no), 'w', newline='') as csvfile:
                    w = csv.writer(csvfile)
                    w.writerows(output)
                    table_no += 1
                    output = []


# For Spain, we need to format table by table:

# In[5]:


# files = ["desstats_all_id_basic.log","desstats_all_id_educ.log", "desstats_all_id_ind.log", 
#          "desstats_sple_spells_basic.log","desstats_sple_id_basic.log"]
# target_name = "descriptive_stats_spa_tab"

file_descriptive = ["desstats_sple_id_basic2011_classic.log"]
target_name = "descriptive_stats_spa_tab_sample"

format_log_files(file_descriptive,pathh,target_name,keywords_start=["Group"],keywords_end=["N","Total"],
                 descriptive_var_list=['max_TC_sample_classic'],loop_tab=True)

files_new = ["desstats_sple_id_educ2011_classic.log"]#"desstats_sple_id_basic2011.log",
target_name = "descriptive_stats_spa_other_sample"

format_log_files(files_new,pathh,target_name,keywords_start=["Group",'max_TC_sample_classic'],keywords_end=["N","Total"],
                 descriptive_var_list=["educ2"],loop_tab=True)


# <a id="dur"></a>
# 
# ### 0. Duration of unstable spells (`tab:desstats_dur`)
# 
# **Mean and Log(variance)** come from the baseline decomposition result CSVs
# (`mu_y` and `lsig_y2` fields):
# - Germany: `archive/germany/Results May 2025/031_decomp.csv`
# - Spain:   `data/intermediate/spain/results/results2011_T_harm.csv`
# 
# **Variance and percentiles** come from the Stata tabstat logs (spell-level,
# `max_TC_sample==2`):
# - Germany: `archive/germany/Results May 2025/05_descriptives.log` Table 9
# - Spain:   `data/intermediate/spain/descriptive_stats/desstats_sple_spells_states2011.log`
# 
# **N** = individual count: Germany 71,046 (from Stata tab4); Spain = `Obs/2` from decomp CSV.
# 
# *Note: Spain numbers differ slightly from the paper because the paper used
# the v20 baseline data; the current files reflect the v21 (2021) update.*
# 

# In[6]:


## Mean (mu_y) and Log(variance) (lsig_y2) from decomposition result CSVs
decomp_ger = pd.read_csv(
    "./data/intermediate/germany/031_decomp_2011.csv", index_col=0)
decomp_spa = pd.read_csv(
    "./data/intermediate/spain/results/results2011_T_harm.csv", index_col=0)

ger_mu_y    = decomp_ger.loc["mu_y",    "Mean"]
ger_lsig_y2 = decomp_ger.loc["lsig_y2", "Mean"]
ger_N_ind   = int(decomp_ger.loc["lsig_y2", "Obs"].replace(",", "")) // 2

spa_mu_y    = decomp_spa.loc["mu_y",    "Mean"]
spa_lsig_y2 = decomp_spa.loc["lsig_y2", "Mean"]
spa_N_ind   = int(decomp_spa.loc["lsig_y2", "Obs"].replace(",", "")) // 2

print(f"Germany: mu_y={ger_mu_y:.3f}, lsig_y2={ger_lsig_y2:.3f}, N={ger_N_ind}")
print(f"Spain:   mu_y={spa_mu_y:.3f}, lsig_y2={spa_lsig_y2:.3f}, N={spa_N_ind}")


# In[7]:


## Helper: parse a "tabstat X Y, by(max_TC_sample)" block from a Stata log
def parse_tabstat_dur(log_path, start_check_fn, end_check_fn):
    """Return dict {group_id: [[val1,val2], ...]} with 10 stat rows per group."""
    stats_order = ["Mean","SD","Min","p10","p25","p50","p75","p90","Max","N"]
    reading, group_id, rows, result = False, None, [], {}
    with open(log_path) as f:
        lines = f.read().splitlines()
    for line in lines:
        lc    = line.replace("|", "")
        words = lc.split()
        bare  = [w.rstrip(",;") for w in words]
        if not words:
            continue
        if not reading and start_check_fn(bare):
            reading, group_id, rows = True, None, []
            continue
        if reading and end_check_fn(bare, line):
            if group_id is not None:
                result[group_id] = rows
            reading = False
        if not reading:
            continue
        if words[0] in ["Summary","Group","max_TC_sample"]:
            continue
        if all(c in "-+| " for c in lc):
            continue
        if words[0] == "Total":
            if group_id is not None:
                result[group_id] = rows
            group_id, rows = "Total", []
            continue
        try:
            vals = [float(w.replace(",","")) for w in words[-2:]]
        except ValueError:
            continue
        if len(words) >= 3:
            if group_id is not None:
                result[group_id] = rows
            group_id, rows = words[0], [vals]
        elif len(words) == 2:
            rows.append(vals)
    return stats_order, result

## Germany Table 9: ". tabstat days_if_P days_if_TU, by(max_TC_sample) ..."
stats_order, ger_dur = parse_tabstat_dur(
    res_ger_file,
    start_check_fn=lambda b: (
        len(b)>=3 and b[0]=="." and b[1]=="tabstat"
        and "days_if_P" in b and "days_if_TU" in b),
    end_check_fn=lambda b, line: (
        b[0]=="." and len(b)>=2 and b[1]!=">")
)
ger_g2 = {stats_order[i]: ger_dur["2"][i] for i in range(len(stats_order))}
tab_ger_dur = pd.DataFrame(ger_g2, index=["days_if_P","days_if_TU"]).T

## Spain log: same tabstat from Descriptive_stats_main.do
stats_order, spa_dur = parse_tabstat_dur(
    pathh + "desstats_sple_spells_states2011.log",
    start_check_fn=lambda b: (
        len(b)>=2 and b[1]=="tabstat" and "days_if_TU" in b),
    end_check_fn=lambda b, line: "log close" in line
)
spa_g2 = {stats_order[i]: spa_dur["2"][i] for i in range(len(stats_order))}
tab_spa_dur = pd.DataFrame(spa_g2, index=["days_if_P","days_if_TU"]).T

tab_ger_dur


# In[8]:


## Combine into paper table (TU spells, max_TC_sample==2)
ger_tu = tab_ger_dur["days_if_TU"]
spa_tu = tab_spa_dur["days_if_TU"]

rows = {
    "Mean (days)":    [ger_mu_y,             spa_mu_y],
    "Variance":       [ger_tu["SD"]**2,       spa_tu["SD"]**2],
    "Log (variance)": [ger_lsig_y2,           spa_lsig_y2],
    "Min":            [ger_tu["Min"],          spa_tu["Min"]],
    "p10":            [ger_tu["p10"],          spa_tu["p10"]],
    "p25":            [ger_tu["p25"],          spa_tu["p25"]],
    "p50":            [ger_tu["p50"],          spa_tu["p50"]],
    "p75":            [ger_tu["p75"],          spa_tu["p75"]],
    "p90":            [ger_tu["p90"],          spa_tu["p90"]],
    "Max":            [ger_tu["Max"],          spa_tu["Max"]],
    "N":              [ger_N_ind,              spa_N_ind],
}
tab_dur = pd.DataFrame(rows, index=["Germany", "Spain"]).T
# print(tab_dur.to_latex(escape=False, float_format="%.3f"))
tab_dur


# <a id="main"></a>
# 
# ### 1. Main descriptive statistics, individual level (`tab:desstats_2+spell`)
# 

# In[9]:


tab_ger_main = pd.read_csv("./output/intermediate/descriptive_stats_ger_tab1.csv",index_col=0)
stats_names = ["Mean", "SD", "Min", "p10", "p25", "p50", "p75", "p90", "Max", "N"]
# stats_index = stats_names *3 + ["Total",]
stats_index = [f"{stat} {i}" for i in range(3) for stat in stats_names] + ["Total",]
tab_ger_main.index = stats_index
tab_ger_main = tab_ger_main.T
tab_ger_main = tab_ger_main.rename(index={"foreig~n": "foreign"})
tab_ger_main


# In[10]:


# tab_spa_main = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab1.csv",index_col=0).T
tab_spa_main = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab_sample1.csv",index_col=0).T
tab_spa_main


# In[11]:


# tab_spa_main = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab1.csv",index_col=0).T
tab_spa_main = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab_sample1.csv",index_col=0)
tab_spa_main.index = stats_index
tab_spa_main = tab_spa_main.T

stats = ['Mean','p50','SD']
tabs_ger, tabs_spa = [],[]
for i in range(3):
    cols_i = [f"{stat} {i}" for stat in stats]
    tab_ger_i, tab_spa_i = tab_ger_main.loc[:,cols_i].T.copy(), tab_spa_main.loc[:,cols_i].T.copy()
    tab_ger_i.index,tab_spa_i.index = ["Mean", "Median", ""], ["Mean", "Median", ""]
    tabs_ger.append(tab_ger_i.T)
    tabs_spa.append(tab_spa_i.T)

tab_ger = pd.concat(tabs_ger,axis=1,keys=range(3))
tab_spa = pd.concat(tabs_spa,axis=1,keys=range(3))
table_merged = pd.concat((tab_ger,tab_spa),axis=1,keys=['Germany','Spain']).T

# table_merged.loc[:,'days_p'] = table_merged.loc[:,'days_p']/365   # disabled: Germany column is now 'days_p~l'; table drops T_S/T_U
# table_merged.loc[:,'days_tu'] = table_merged.loc[:,'days_tu']/365   # disabled: Germany column is now 'days_p~l'; table drops T_S/T_U

colnames_fixed = ['Age', 'Female', 'Non-national', r'$N_S$', r"$N_U$", r"$T_S$",r"$T_U$"]
table_merged.rename(columns=dict(zip(list(table_merged.keys()),colnames_fixed)),inplace=True)

# table_merged.index = ["Mean", "Median", ""]*6
table_merged = table_merged.astype('object')
for row in range(2,20,3):
    table_merged.iloc[row,:] = table_merged.iloc[row,:].apply(lambda x: "("+str(np.round(x,2))+")")

table_merged


# In[12]:


# tab_spa_main = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab1.csv",index_col=0).T
tab_spa_main = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab_sample1.csv",index_col=0)
tab_spa_main.index = stats_index
tab_spa_main = tab_spa_main.T

stats = ['Mean','SD','N']
tabs_ger, tabs_spa = [],[]
for i in range(3):
    cols_i = [f"{stat} {i}" for stat in stats]
    tab_ger_i, tab_spa_i = tab_ger_main.loc[:,cols_i].T.copy(), tab_spa_main.loc[:,cols_i].T.copy()
    tab_ger_i.index,tab_spa_i.index = ["Mean",  "", "N"], ["Mean", "","N"]
    tabs_ger.append(tab_ger_i.T)
    tabs_spa.append(tab_spa_i.T)

tab_ger = pd.concat(tabs_ger,axis=1,keys=range(3))
tab_spa = pd.concat(tabs_spa,axis=1,keys=range(3))
table_merged = pd.concat((tab_ger,tab_spa),axis=1,keys=['Germany','Spain']).T

# table_merged.loc[:,'days_p'] = table_merged.loc[:,'days_p']/365
# table_merged.loc[:,'days_tu'] = table_merged.loc[:,'days_tu']/365

colnames_fixed = ['Age', 'Female', 'Non-national', r'$N_S$', r"$N_U$", r"$T_S$",r"$T_U$"]
table_merged.rename(columns=dict(zip(list(table_merged.keys()),colnames_fixed)),inplace=True)

table_merged = table_merged[['Age', 'Female', 'Non-national', r'$N_S$', r"$N_U$"]]

# # table_merged.index = ["Mean", "Median", ""]*6
table_merged = table_merged.astype('object')
# for row in range(1,12,2):
#     table_merged.iloc[row,:] = table_merged.iloc[row,:].apply(lambda x: "("+str(np.round(x,2))+")")

table_merged


# In[13]:


print(table_merged.to_latex(escape=False,float_format="%.2f"))


# <a id="whole"></a>
# 
# ### 1b. Whole sample including never-unstable (`tab:desstats_all`)
# 
# Same variables and layout as the main table, but on the **whole sample including
# never-unstable individuals** (groups `max_TC_sample` = 0, 1, 2):
# 
# - **Germany:** Table 2 of `data/intermediate/germany/05_descriptives.log` -> `Results/descriptive_stats_ger_tab1.csv`
# - **Spain:** `data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab_sample1.csv` (group 0 = never unstable, included)
# 
# *Note:* Spain's permanent-days column is `days_p~l` vs Germany's `days_p`; both map to $T_S$ (converted to years).

# In[14]:


## -- Whole-sample descriptive statistics, incl. never-unstable (max_TC_sample 0/1/2) --
## Germany: Table 9 of 05_descriptives.log (Jenny's windowed-truncation fix, 2026-07-08)
##          -> Results/descriptive_stats_ger_tab8.csv (the parser numbers tables by
##          order of appearance, which shifted when the do-file was restructured;
##          the do-file's own "Table 9" comment is the source of truth).
## Spain:   descriptive_stats_spa_tab_sample1.csv (group 0 = never unstable, included)
## Both countries key on 'days_p~l' (days_p_total / days_p_all) for T_S.

tab_ger_whole = pd.read_csv("./output/intermediate/descriptive_stats_ger_tab8.csv", index_col=0)
tab_ger_whole.index = stats_index
tab_ger_whole = tab_ger_whole.T
tab_ger_whole = tab_ger_whole.rename(index={"foreig~n": "foreign"})

# Rebuild tab_spa_main here so this block does not depend on statement order:
# an earlier assignment does a naive .T without stats_index.
tab_spa_main = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab_sample1.csv", index_col=0)
tab_spa_main.index = stats_index
tab_spa_main = tab_spa_main.T

_VARS = ['age', 'sex_d', 'foreign', 'n_PC', 'n_TC_s~e', 'days_p~l', 'days_tu']
_COLS = ['Age', 'Female', 'Non-national', r'$N_S$', r'$N_U$', r'$T_S$', r'$T_U$']

def _whole_df(tab, country):
    """Mean / Median / SD per group (0,1,2) for one country; days -> years."""
    recs = {}
    for i in range(3):
        for stat, key in [("Mean", "Mean"), ("Median", "p50"), ("SD", "SD")]:
            vals = [float(tab.loc[v, f'{key} {i}']) for v in _VARS]
            vals[5] /= 365.0   # T_S : days -> years
            vals[6] /= 365.0   # T_U : days -> years
            recs[(country, i, stat)] = vals
    return pd.DataFrame(recs, index=_COLS).T

table_whole = pd.concat([_whole_df(tab_ger_whole, "Germany"),
                         _whole_df(tab_spa_main, "Spain")])

# LaTeX (Mean / Median / (SD) per group), matching the paper layout
_colspec = "l" * (3 + len(_COLS))
_lines = [rf"\begin{{tabular}}{{{_colspec}}}", r"\toprule",
          r" &  &  & " + " & ".join(_COLS) + r" \\", r"\midrule"]
for ci, country in enumerate(["Germany", "Spain"]):
    if ci:
        _lines.append(r"\midrule")
    for i in range(3):
        mean = table_whole.loc[(country, i, "Mean")]
        med  = table_whole.loc[(country, i, "Median")]
        sd   = table_whole.loc[(country, i, "SD")]
        head = country if i == 0 else ""
        _lines.append(f"{head} & {i} & Mean & " + " & ".join(f"{v:.2f}" for v in mean) + r" \\")
        _lines.append(r" &  & Median & "        + " & ".join(f"{v:.2f}" for v in med)  + r" \\")
        _lines.append(r" &  &  & "              + " & ".join(f"({np.round(v, 2)})" for v in sd) + r" \\")
_lines += [r"\bottomrule", r"\end{tabular}"]
tex_whole_out = "\n".join(_lines)
print(tex_whole_out)

table_whole


# <a id="educ"></a>
# 
# ### 2. Education breakdown (`tab:desstats_2+spell`)
# 

# In[15]:


tab_ger_educ = pd.read_csv("./output/intermediate/descriptive_stats_ger_tab4.csv",index_col=0)
# tab_ger_educ.loc[:,'Freq.'] = tab_ger_educ.loc[:,'Freq.'].apply(lambda x: x.replace(",","")).apply(pd.to_numeric)
# tab_ger_educ.loc[:,'Cum.'] = tab_ger_educ.loc[:,'Cum.'].apply(pd.to_numeric)

tab_ger_educ.loc["0",:] = tab_ger_educ.loc["0",:].apply(lambda x: x.replace(",",""))
tab_ger_educ = tab_ger_educ.astype(float)
tab_ger_educ.loc['Primary School',:] = tab_ger_educ.loc['Primary School',:]+tab_ger_educ.loc['0',:]
tab_ger_educ.iloc[3,:] = tab_ger_educ.iloc[3,:]+tab_ger_educ.iloc[1,:]
tab_ger_educ = tab_ger_educ.iloc[2:,:]

tab_spa_educ = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_other_sample1.csv",index_col=0)
for i in range(tab_spa_educ.shape[1]):
    tab_spa_educ.iloc[:,i] = tab_spa_educ.iloc[:,i].apply(lambda x: x.replace(",",""))
tab_spa_educ = tab_spa_educ.astype(float)

tab_ger_educ.head()


# In[16]:


pd.read_csv("./output/intermediate/descriptive_stats_ger_tab6.csv",index_col=0)


# In[17]:


stats = ['Mean','SD']
tabs_ger, tabs_spa = [],[]
for i in range(3):
    cols_i = [f"{stat} {i}" for stat in stats]
    tab_ger_i, tab_spa_i = tab_ger_main.loc[:,cols_i].T.copy(), tab_spa_main.loc[:,cols_i].T.copy()
    tab_ger_i.index,tab_spa_i.index = ["Mean", ""], ["Mean", ""]
    tabs_ger.append(tab_ger_i.T)
    tabs_spa.append(tab_spa_i.T)

tab_ger = pd.concat(tabs_ger,axis=1,keys=range(3))
tab_spa = pd.concat(tabs_spa,axis=1,keys=range(3))
table_merged2 = pd.concat((tab_ger,tab_spa),axis=1,keys=['Germany','Spain']).T
table_merged2 = table_merged2.loc[:,["age","sex_d","foreign"]]

edu_names = list(tab_ger_educ.index[np.where(tab_ger_educ.index!=" ")[0]])[:-1]
for i, educ in enumerate(edu_names):
    uni_array = np.hstack((tab_ger_educ.iloc[i*2+1,:-1],tab_spa_educ.iloc[i*2+1,:-1]))
    uni_array = np.insert(uni_array, range(1, uni_array.size+1), 0)
    table_merged2[educ] = uni_array
table_merged2 = table_merged2.T

tab_new = table_merged2.iloc[:,np.arange(0,table_merged2.shape[1],2)].copy()
tab_std = table_merged2.iloc[:,np.arange(1,table_merged2.shape[1],2)].copy()
tab_new = tab_new.droplevel(2,axis=1)
tab_std = tab_std.droplevel(2,axis=1)
tab_all = pd.concat([tab_new.iloc[:1,:].T,tab_std.iloc[0,:]],axis=1)
var_list = np.array(table_merged2.index)
for i in range(1,var_list.size):
    tab_all = pd.concat([tab_all,tab_new.iloc[i,:].T,tab_std.iloc[i,:]],axis=1)
tab_all = tab_all.T
var_list_ext = np.array(['Age', 'Female', 'Non-national', "Primary", "Lower Secondary", "Upper Secondary", "College"])
tab_all.index = np.insert(var_list_ext, range(1, var_list_ext.size+1), "")

tab_all = tab_all.astype('object')
for row in range(1,tab_all.shape[0],2):
    tab_all.iloc[row,:] = tab_all.iloc[row,:].apply(lambda x: "("+str(np.round(x,2))+")")

tab_mean3 = table_merged.iloc[::3,-4:].T.copy()
tab_std3 = table_merged.iloc[2::3,-4:].T.copy()
tab_mean3 = tab_mean3.droplevel(2,axis=1)
tab_std3 = tab_std3.droplevel(2,axis=1)

tab_all = tab_all.T
var_list = np.array(tab_mean3.index)
for i in range(var_list.size):
    tab_all = pd.concat([tab_all,tab_mean3.iloc[i,:].T,tab_std3.iloc[i,:].T.rename("")],axis=1)
tab_all = tab_all.T

tab_all


# In[18]:


print(tab_all.to_latex(escape=False,float_format="%.2f"))


# In[19]:


edu_dict = dict(zip(['1','2','3','4'],['Primary School', 'Lower Secondary School', 'Upper Secondary School','University']))

# tab_spa_educ = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_tab2.csv",index_col=0,keep_default_na=False,skip_blank_lines=True)
tab_spa_educ = pd.read_csv("./data/intermediate/spain/descriptive_stats/descriptive_stats_spa_other_sample1.csv",index_col=0)
for i in range(tab_spa_educ.shape[1]):
    tab_spa_educ.iloc[:,i] = tab_spa_educ.iloc[:,i].apply(lambda x: x.replace(",",""))
tab_spa_educ = tab_spa_educ.astype(float)
# tab_spa_educ = tab_spa_educ.loc[["1","2","3","4"],:].copy()
tab_spa_educ.rename(index=edu_dict,inplace='True')
# tab_spa_educ.loc[:,:] = tab_spa_educ.loc[:,:].apply(lambda x: x.replace(",","")).apply(pd.to_numeric)
# tab_spa_educ.loc[:,'Cum.'] = tab_spa_educ.loc[:,'Cum.'].apply(pd.to_numeric)
# tab_spa_educ.loc['Total',:] = np.sum(tab_spa_educ.values,axis=0)
tab_spa_educ


# In[20]:


tab_ger_educ


# In[21]:


table_educ = pd.concat(
    (tab_ger_educ.reset_index(drop=True), tab_spa_educ.reset_index(drop=True)),
    axis=1, keys=['Germany','Spain']
)
table_educ.index = list(tab_ger_educ.index)

table_educ
print(table_educ.to_latex(escape=False,float_format="%.2f"))


# In[22]:


## ── Industry of last employment: parse log files ──────────────────────────

def parse_ind_tab_log(log_path, start_marker):
    """
    Parse a Stata 'tab ind_short max_TC_sample [if ...], column' output block.

    Each industry is printed as two alternating lines:
      1. Frequency row : <label text>  <n0>  <n1>  <n2>  <n_total>
      2. Percentage row:               <p0>  <p1>  <p2>  <p_total>  (blank label)

    To correctly handle labels like 'Manufacturing 1' (where the number is
    part of the label, not a count), we split by taking the *last 4 tokens*
    as the numeric values and everything before them as the label.

    Returns:
        df_pct  : DataFrame of column-% shares; rows=industry labels,
                  columns=['No TC', '1 TC', '2+ TC', 'Total']
        n_total : list [N_0, N_1, N_2, N_total] from the Total frequency row
    """

    def _split_label_nums(words):
        """Take last 4 convertible tokens as numbers; rest is the label."""
        nums       = []
        label_parts = list(words)
        while label_parts and len(nums) < 4:
            try:
                nums.insert(0, float(label_parts[-1].replace(',', '')))
                label_parts.pop()
            except ValueError:
                break  # non-numeric token reached
        return label_parts, nums

    reading       = False
    rows          = []
    waiting_pct   = False
    current_label = None
    current_freq  = None

    with open(log_path, encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    for line in lines:
        if not reading:
            if start_marker in line:
                reading = True
            continue

        clean    = line.replace('|', ' ').rstrip('\n')
        stripped = clean.strip()
        if not stripped:
            continue
        # Skip decorative separator lines
        if all(c in '-+| \t' for c in line.rstrip('\n')):
            continue

        words = stripped.split()
        if not words:
            continue
        # Skip header / log-open / log-close lines
        if words[0] in ['Key', 'frequency', 'column', 'max_TC_sample',
                         'Industry', 'ind_short', 'name:', 'log:', 'opened', 'closed']:
            continue

        label_parts, nums = _split_label_nums(words)
        if len(nums) < 4:
            continue  # malformed line

        if label_parts:
            # Non-empty label → frequency row
            current_label = ' '.join(label_parts)
            current_freq  = nums
            waiting_pct   = True
        elif waiting_pct and current_label is not None:
            # Empty label → percentage row following the previous frequency row
            rows.append({'label': current_label, 'freq': current_freq, 'pct': nums})
            waiting_pct   = False
            current_label = None
            current_freq  = None
            if rows[-1]['label'] == 'Total':
                break  # end of table

    total_row = next((r for r in rows if r['label'] == 'Total'), None)
    ind_rows  = [r for r in rows if r['label'] != 'Total']

    cols   = ['No TC', '1 TC', '2+ TC', 'Total']
    df_pct = pd.DataFrame(
        [r['pct'][:4] for r in ind_rows],
        index=[r['label'] for r in ind_rows],
        columns=cols
    )
    df_freq = pd.DataFrame(
        [r['freq'][:4] for r in ind_rows],
        index=[r['label'] for r in ind_rows],
        columns=cols
    ).astype(int)
    n_total = [int(x) for x in total_row['freq'][:4]] if total_row else [None] * 4
    return df_pct, df_freq, n_total


# Germany: individual-level table restricted to samesame==1 (one observation per person)
tab_ger_ind, freq_ger_ind, n_ger_ind = parse_ind_tab_log(
    res_ger_file,
    start_marker='tab ind_short max_TC_sample if samesame==1, column'
)

# Spain: standalone log file – trigger on the column-header line
tab_spa_ind, freq_spa_ind, n_spa_ind = parse_ind_tab_log(
    './data/intermediate/spain/descriptive_stats/desstats_sple_id_ind2011_short.log',
    start_marker='ind_short'
)

# ── Rename truncated Stata labels to clean full names ─────────────────────
# Germany: based on WZ 2008 codes in germany/01_clean.do
ger_label_map = {
    'NA':                    'Missing',
    'Agriculture':           'Agriculture',
    'Manufacturing 1':       'Manufacturing (consumer goods)',
    'Manufacturing 2':       r'Manufacturing (chemicals \& metals)',
    'Manufacturing 3':       r'Manufacturing (machinery \& electronics)',
    'Construction':          'Construction',
    'Wholesale and Retail':  'Wholesale and Retail Trade',
    'Transportation and St': 'Transportation and Storage',
    'Hospitality':           'Hospitality',
    'Business Services':     'Business Services',
    'Financial and Insuran': 'Financial and Insurance',
    'Public Admin and Defe': r'Public Admin.\ and Defence',
    'Education':             'Education',
    'Health Services':       'Health Services',
}

# Spain: based on CNAE 2009 codes in spain/format_files/industry_clean.do
spa_label_map = {
    'NA':                    'Missing',
    'Agriculture':           'Agriculture',
    'Extractive':            'Mining and Quarrying',
    'Manufactures (primary': 'Manufacturing (primary)',
    'Manufactures (machine': 'Manufacturing (machinery)',
    'Manufactures (detail':  'Manufacturing (detail and repair)',
    'Energy, gas, residual': 'Energy, Gas and Waste Treatment',
    'Construction':          'Construction',
    'Retail and repairs':    'Retail and Repairs',
    'Transport and storage': 'Transport and Storage',
    'Hospitality':           'Hospitality',
    'Communication and pro': 'Communication and Programming',
    'Financial':             'Financial Activities',
    'Real State':            'Real Estate',
    'Professional and scie': 'Professional and Scientific Services',
    'Auxiliary services (c': r'Auxiliary Services (cleaning, security)',
    'Public Administration': 'Public Administration',
    'Education':             'Education',
    'Health and Social Ser': 'Health and Social Services',
    'Other Services':        'Other Services',
}

tab_ger_ind.index  = [ger_label_map.get(l, l) for l in tab_ger_ind.index]
freq_ger_ind.index = tab_ger_ind.index
tab_spa_ind.index  = [spa_label_map.get(l, l) for l in tab_spa_ind.index]
freq_spa_ind.index = tab_spa_ind.index

print('Germany industry (% column share):')
display(tab_ger_ind)
print('\nSpain industry (% column share):')
display(tab_spa_ind)


# In[23]:


## ── Generate LaTeX for industry tables (main sample: max_TC_sample == 2) ────
#
# Two columns per country: count (N) and column % share for max_TC_sample == 2.

def _ind_tex(df_pct, df_freq, n_total):
    """Format count + % share for the 2+ TC group as a LaTeX tabular."""
    lines_ind = [
        r'\begin{tabular}{lrr}',
        r'\toprule',
        r'Industry & $N$ & Share (\%) \\',
        r'\midrule',
    ]
    for label in df_pct.index:
        n   = int(df_freq.loc[label, '2+ TC'])
        pct = df_pct.loc[label, '2+ TC']
        lines_ind.append(f"{label} & {n:,} & {pct:.2f} \\\\")

    lines_ind.append(r'\midrule')
    lines_ind.append(f"Total & {int(n_total[2]):,} & 100.00 \\\\")
    lines_ind += [r'\bottomrule', r'\end{tabular}']
    return '\n'.join(lines_ind)


tex_ger_ind = _ind_tex(tab_ger_ind, freq_ger_ind, n_ger_ind)
tex_spa_ind = _ind_tex(tab_spa_ind, freq_spa_ind, n_spa_ind)

print('% Table 3: Germany industry (max_TC_sample==2)')
print(tex_ger_ind)
print()
print('% Table 4: Spain industry (max_TC_sample==2)')
print(tex_spa_ind)


# ---
# ## Export: write both tables to `output/tables/descriptive_stats_tables.tex`

# In[24]:


## ── Table 1: Duration of unstable spells (tab:desstats_dur) ─────────────────
#
# Row formatting rules (matching paper):
#   Mean (days)    : 2 decimal places
#   Variance       : comma-separated, 1 decimal place
#   Log (variance) : 3 decimal places
#   Min/pXX/Max    : integer, comma-separated
#   N              : integer, comma-separated

def _fmt_dur_row(label, g, s):
    if label in ("Min", "p10", "p25", "p50", "p75", "p90", "Max"):
        suffix = r"\\"
        return f"{label} & {int(g):,} & {int(s):,} {suffix}"
    elif label == "N":
        return f"N & {int(g):,} & {int(s):,} \\\\[5pt]"
    elif label == "Mean (days)":
        return f"{label} & {g:,.2f} & {s:,.2f} \\\\"
    elif label == "Variance":
        return f"{label} & {g:,.1f} & {s:,.1f} \\\\"
    elif label == "Log (variance)":
        return f"{label} & {g:.3f} & {s:.3f} \\\\"

stat_order_dur = [
    "Mean (days)", "Variance", "Log (variance)",
    "Min", "p10", "p25", "p50", "p75", "p90", "Max", "N",
]

lines_dur = [
    r"\begin{tabular}{lll}",
    r"\toprule",
    r" & Germany & Spain \\",
    r"\midrule",
]
for stat in stat_order_dur:
    lines_dur.append(_fmt_dur_row(stat,
                                  tab_dur.loc[stat, 'Germany'],
                                  tab_dur.loc[stat, 'Spain']))
lines_dur += [r"\bottomrule", r"\end{tabular}"]

tex_dur_out = "\n".join(lines_dur)
print(tex_dur_out)


# In[25]:


## ── Table 2: Main descriptive statistics (tab:desstats_2+spell) ─────────────
#
# Shows only max_TC_sample == 2 (the paper's main sample).
# Continuous vars: Mean (2 dp) + (SD) below.
# Education: percentage (2 dp) from tab_ger_educ / tab_spa_educ,
#            group-2 column = positional index 2, percentage row = i*2+1.
# N_S, N_U : Mean (2 dp) + (SD) below.
# N        : integer, comma-separated.

def _mfmt(v):   return f"{float(v):.2f}"
def _sdfmt(v):  return f"({float(v):.2f})"

lines_main = [
    r"\begin{tabular}{lcc}",
    r"\toprule",
    r" & Germany & Spain \\",
    r"\midrule",
]


# ---- Continuous: Age, Female, Non-national ----
for label, var in [('Age', 'age'), ('Female', 'sex_d'), ('Non-national', 'foreign')]:
    gm = tab_ger_main.loc[var, 'Mean 2'];  gs = tab_ger_main.loc[var, 'SD 2']
    sm = tab_spa_main.loc[var, 'Mean 2'];  ss = tab_spa_main.loc[var, 'SD 2']
    lines_main.append(f"{label} & {_mfmt(gm)} & {_mfmt(sm)} \\\\")
    lines_main.append(f"    & {_sdfmt(gs)} & {_sdfmt(ss)} \\\\")

# ---- Education shares (%) ----
# tab_ger_educ / tab_spa_educ: alternating rows count / pct.
# After tab_ger_educ = tab_ger_educ.iloc[2:], order is:
#   iloc[0] Primary counts, iloc[1] Primary pct,
#   iloc[2] Lower Sec counts, iloc[3] Lower Sec pct, ...
# Column positional index 2  = group max_TC_sample == 2.
for i, label in enumerate(['Primary', 'Lower Secondary', 'Upper Secondary', 'College']):
    g_pct = tab_ger_educ.iloc[i * 2 + 1, 2]
    s_pct = tab_spa_educ.iloc[i * 2 + 1, 2]
    lines_main.append(f"{label} & {g_pct:.2f} & {s_pct:.2f} \\\\")
    lines_main.append(f"    & (0.00) & (0.00) \\\\")

lines_main.append(r"\midrule")

# ---- N_S and N_U ----
for label, var in [
    (r"$N_S$: number stable spells",   'n_PC'),
    (r"$N_U$: number unstable spells", 'n_TC_s~e'),
]:
    gm = tab_ger_main.loc[var, 'Mean 2'];  gs = tab_ger_main.loc[var, 'SD 2']
    sm = tab_spa_main.loc[var, 'Mean 2'];  ss = tab_spa_main.loc[var, 'SD 2']
    lines_main.append(f"{label} & {_mfmt(gm)} & {_mfmt(sm)} \\\\")
    lines_main.append(f"   & {_sdfmt(gs)} & {_sdfmt(ss)} \\\\")

lines_main.append(r"\hline \hline")

# ---- N (total individual count) ----
g_N = int(tab_ger_main.loc['age', 'N 2'])
s_N = int(tab_spa_main.loc['age', 'N 2'])
lines_main.append(f"$N$ & {g_N:,} & {s_N:,} \\\\")

lines_main += [r"\bottomrule", r"\end{tabular}"]

tex_main_out = "\n".join(lines_main)
print(tex_main_out)


# In[26]:


## ── Write all tables to output/tables/descriptive_stats_tables.tex ───────────────────
output_tex = "./output/tables/descriptive_stats_tables.tex"

with open(output_tex, 'w', encoding='utf-8') as f:
    f.write("% Descriptive Statistics Tables\n")
    f.write("% Auto-generated by 'Descriptive Stats Tables.ipynb'\n")
    f.write("% Do not edit manually - re-run the notebook to update.\n\n")
    f.write("% Table 1: Duration of unstable spells (tab:desstats_dur)\n")
    f.write(tex_dur_out)
    f.write("\n\n")
    f.write("% Table 2: Descriptive statistics (tab:desstats_2+spell)\n")
    f.write(tex_main_out)
    f.write("\n\n")
    f.write("% Table 2b: Whole sample incl. never-unstable (tab:desstats_all)\n")
    f.write(tex_whole_out)
    f.write("\n\n")
    f.write("% Table 3: Industry of last employment -- Germany\n")
    f.write(tex_ger_ind)
    f.write("\n\n")
    f.write("% Table 4: Industry of last employment -- Spain\n")
    f.write(tex_spa_ind)
    f.write("\n")

print(f"Saved: {output_tex}")

