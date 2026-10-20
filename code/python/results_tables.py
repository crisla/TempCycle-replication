#!/usr/bin/env python
# coding: utf-8

# # Formating Results tables Notebook
# 
# From the stata log files to latex format.
# 
# The strategy is vary simple: read the .log files created by STATA with the results from Germany and Spain, and combine them into latex tables using Pandas.
# 
# ## Preamble
# 
# Loading modules and custom functions

# In[554]:


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


# In[555]:


def pass_to_csv(file_name,path_res,path_out="",keyword="Variable"):
    results_now = 0
    table_num = 0
    looking_for_sigy = False
    if path_out == "":
        path_out = path_res

    def write_output(output, table_num):
        if table_num == 0:
            fname = path_out + file_name + ".csv"
        else:
            fname = path_out + file_name + "_{}".format(table_num+1) + ".csv"
        with open(fname, 'w+') as csvfile:
            w = csv.writer(csvfile)
            w.writerows(output)
        return table_num + 1

    with open(path_res+file_name+".log") as file:
        lines = file.read().splitlines()
        output = []
        for line in lines:
            line = line.replace('|','')
            words = line.split()

            # New table header: flush any pending output first
            if len(words)>1 and words[0] == keyword:
                if output:
                    table_num = write_output(output, table_num)
                    output = []
                looking_for_sigy = False
                results_now = 1

            # Collect data rows
            if len(words)>5 and results_now:
                output.append(line.split())

            # mu_y: stop collecting main rows, wait for optional sig_y
            if len(words)>5 and words[0] == "mu_y":
                results_now = 0
                looking_for_sigy = True

            # Optional sig_y line immediately after mu_y (Spain v21 only)
            # Exclude the mu_y line itself (already handled above)
            if looking_for_sigy and len(words)>5 and words[0] != "mu_y":
                if words[0] == "sig_y":
                    output.append(line.split())
                looking_for_sigy = False
                table_num = write_output(output, table_num)
                output = []

        # Flush any remaining output (e.g. Germany logs that end after mu_y)
        if output:
            table_num = write_output(output, table_num)

def first_format(dataset,label):
    dataset['N'] = dataset.loc['Obs'].iloc[0]
    dataset['N'] = dataset['N'].apply(lambda x: x.replace(',',''))
    dataset['N'] = dataset['N'].apply(lambda x: float(x)/2).apply(lambda x: "{:,.0f}".format(float(x)))
    dataset = dataset.rename(index={'Mean':label})
    dataset = dataset.loc[label].copy()
    return dataset

def format_res_table(tables, include_sd=False):
    names = ['lsig_y2','sig_x','lsig_c','lsig_e2','lsig_b2','lpsig_c','lpsig_x','lpsig_e','lpsig_b','N','mu_y','sig_y']
    
    table_res = pd.concat(tables,axis=1).T
    
    old_names_var = ['lsig_y2','sig_x','lsig_c','lsig_e2','lsig_b2','lpsig_c','lpsig_x','lpsig_e','lpsig_b','mu_y','sig_y']
    new_names_var = [r'$\sigma^{2}_y$',r'$\sigma^{2}_n$',r'$\sigma^{2}_c$',r'$\sigma^{2}_e$',r'$\sigma^{2}_b$',
                     r'% constant',r'% spell number','% duration dependence','% heterogeneity','Average duration (days)','Std. duration (days)']
    reorder_cols = [r'$\sigma^{2}_y$',r'$\sigma^{2}_c$',r'$\sigma^{2}_n$',r'$\sigma^{2}_e$',r'$\sigma^{2}_b$',
                     r'% constant',r'% spell number','% duration dependence','% heterogeneity','N','Average duration (days)']
    if include_sd:
        reorder_cols.append('Std. duration (days)')
    
    table_res.rename(columns=dict(zip(old_names_var,new_names_var)),inplace='True')
    table_res = table_res.reindex(columns=reorder_cols)
    
    # sig_y is variance in levels; convert to SD (only when included)
    if include_sd:
        table_res['Std. duration (days)'] = table_res['Std. duration (days)'].apply(lambda x: np.sqrt(float(x)))
    
    table_res = table_res.T

    return table_res


# ## 1 Baseline results
# 
# ### 1.1 General - Germany

# In[556]:


path_res = "./data/intermediate/germany/"

# Baseline decomp
pass_to_csv("031_decomp_2011",path_res)
ger_res = pd.read_csv(path_res+"031_decomp_2011.csv",index_col=0).T
ger_res = first_format(ger_res,'Germany')
# SD in levels from 05_descriptives-2.log (tabstat days, baseline sample)
ger_res['sig_y'] = 253701.2
# No outliers
pass_to_csv("032_decomp",path_res)
ger_res_noout = pd.read_csv(path_res+"032_decomp.csv",index_col=0).T
ger_res_noout = first_format(ger_res_noout,'Germany')


# ### Spain

# In[557]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"
# Baseline decomp
pass_to_csv("results2011_T_harm",path_res,path_out = path_out)
spa_res_11 = pd.read_csv(path_out+"results2011_T_harm.csv",index_col=0).T
spa_res_11 = first_format(spa_res_11,'Spain')
# No outliers
pass_to_csv("results2011_noout_T_harm",path_res,path_out = path_out)
spa_res_11_noout = pd.read_csv(path_out+"results2011_noout_T_harm.csv",index_col=0).T
spa_res_11_noout = first_format(spa_res_11_noout,'Spain')


# In[558]:


format_res_table([ger_res,spa_res_11], include_sd=True)


# ### 1.2 No outliers

# In[559]:


print(format_res_table([ger_res_noout,spa_res_11_noout]).to_latex(escape=False,float_format="%.3f"))


# ### 1.3 Different Time Windows, Spain

# In[560]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"
years = [2011, 2005, 1999, 1992]
tables = []
tables_noout = []

for year in years:
    # Baseline decomp
    pass_to_csv("results{}_T_harm".format(year),path_res,path_out = path_out)
    spa_res_x = pd.read_csv(path_out+"results{}_T_harm.csv".format(year),index_col=0).T
    spa_res_x = first_format(spa_res_x,str(year))
    tables.append(spa_res_x)
    # No outliers
    pass_to_csv("results{}_noout_T_harm".format(year),path_res,path_out = path_out)
    spa_res_x_noout = pd.read_csv(path_out+"results{}_noout_T_harm.csv".format(year),index_col=0).T
    spa_res_x_noout = first_format(spa_res_x_noout,str(year))
    tables_noout.append(spa_res_x_noout)


# In[561]:


print(format_res_table(tables, include_sd=True))


# In[562]:


print(format_res_table(tables, include_sd=True).to_latex(escape=False,float_format="%.3f"))


# ## 2. Education
# 
# ### Germany

# In[563]:


path_res = "./data/intermediate/germany/"
ed_levels = ["college","higher","secondary","primary"]
res_ger_edu = []

for edu in ed_levels:
    pass_to_csv("036_decomp_"+edu,path_res)
    ger_res = pd.read_csv(path_res+"036_decomp_{}.csv".format(edu),index_col=0).T
    ger_res = first_format(ger_res,edu)
    res_ger_edu.append(ger_res)


# In[564]:


format_res_table(res_ger_edu, include_sd=True)


# ### Spain

# In[565]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"
res_spa_edu = []

for edu in ed_levels:
    pass_to_csv("results2011_{}_T_harm".format(edu),path_res,path_out = path_out)
    spa_res = pd.read_csv(path_out+"results2011_{}_T_harm.csv".format(edu),index_col=0).T
    spa_res = first_format(spa_res,edu)
    res_spa_edu.append(spa_res)


# In[566]:


format_res_table(res_spa_edu, include_sd=True)


# In[567]:


print(format_res_table(res_ger_edu, include_sd=True).to_latex(escape=False,float_format="%.3f"))


# In[568]:


print(format_res_table(res_spa_edu, include_sd=True).to_latex(escape=False,float_format="%.3f"))


# ## 3. Sex
# 
# ### Germany

# In[569]:


path_res = "./data/intermediate/germany/"
sexes = ['female','male']
res_ger_sex = []

pass_to_csv("033_decomp",path_res)
ger_res_fem = pd.read_csv(path_res+"033_decomp_2.csv",index_col=0).T
ger_res_fem = first_format(ger_res_fem,"female")
ger_res_mal = pd.read_csv(path_res+"033_decomp.csv",index_col=0).T
ger_res_mal = first_format(ger_res_mal,"male")


# ### Spain

# In[570]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"

pass_to_csv("results2011_fem_T_harm",path_res,path_out = path_out)
spa_res_fem = pd.read_csv(path_out+"results2011_fem_T_harm.csv".format(edu),index_col=0).T
spa_res_fem = first_format(spa_res_fem,"female")

pass_to_csv("results2011_mal_T_harm",path_res,path_out = path_out)
spa_res_mal = pd.read_csv(path_out+"results2011_mal_T_harm.csv".format(edu),index_col=0).T
spa_res_mal = first_format(spa_res_mal,"male")


# In[571]:


format_res_table([ger_res_fem,ger_res_mal,spa_res_fem,spa_res_mal], include_sd=True)


# In[572]:


print(format_res_table([ger_res_fem,ger_res_mal,spa_res_fem,spa_res_mal], include_sd=True).to_latex(escape=False,float_format="%.3f"))


# ## Different Time Windows

# In[573]:


path_res = "./data/intermediate/germany/"
path_out = "./data/intermediate/germany/"

files = [
    ("031_decomp_2011", "2011"),
    ("031_decomp_2014", "2014"),
    ("031_decomp_2016", "2016"),
]

tables_1416 = []

for stub, year in files:
    pass_to_csv(stub, path_res, path_out=path_out)
    df = pd.read_csv(f"{path_out}{stub}.csv", index_col=0).T
    df = first_format(df, year)
    tables_1416.append(df)

# Expose the 2014/2016 time-window tables as named variables for the export cell.
# (The notebook relies on these existing in kernel state; define them explicitly
# so the script is self-contained.  tables_1416 = [2011, 2014, 2016].)
ger_res_2014 = tables_1416[1]
ger_res_2016 = tables_1416[2]


# In[574]:


format_res_table(tables_1416, include_sd=True)


# In[575]:


print(
    format_res_table(
        tables_1416,
        include_sd=True
    ).to_latex(
        escape=False,
        float_format="%.3f"
    )
)


# In[576]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"
years = [2011, 2005, 1999, 1992]
tables_f = []
tables_m = []

for year in years:
    pass_to_csv("results{}_fem_T_harm".format(year),path_res,path_out = path_out)
    spa_res_fem_i = pd.read_csv(path_out+"results{}_fem_T_harm.csv".format(year),index_col=0).T
    spa_res_fem_i = first_format(spa_res_fem_i,year)
    tables_f.append(spa_res_fem_i)
    
    pass_to_csv("results{}_mal_T_harm".format(year),path_res,path_out = path_out)
    spa_res_mal_i = pd.read_csv(path_out+"results{}_mal_T_harm.csv".format(year),index_col=0).T
    spa_res_mal_i = first_format(spa_res_mal_i,year)
    tables_m.append(spa_res_mal_i)


# In[577]:


format_res_table(tables_f+tables_m, include_sd=True)


# In[578]:


print(format_res_table(tables_f+tables_m, include_sd=True).to_latex(escape=False,float_format="%.3f"))


# ## 3. Age
# 
# ### Germany

# In[579]:


path_res = "./data/intermediate/germany/"

pass_to_csv("034_decomp_25_35",path_res)
ger_res_25_35 = pd.read_csv(path_res+"034_decomp_25_35.csv",index_col=0).T
ger_res_25_35 = first_format(ger_res_25_35,'25-35')

pass_to_csv("034_decomp_35_55",path_res)
ger_res_35_55 = pd.read_csv(path_res+"034_decomp_35_55.csv",index_col=0).T
ger_res_35_55 = first_format(ger_res_35_55,'35-55')


# ### Spain

# In[580]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"

pass_to_csv("results2011_2535_T_harm",path_res,path_out = path_out)
spa_res_25_35 = pd.read_csv(path_out+"results2011_2535_T_harm.csv",index_col=0).T
spa_res_25_35 = first_format(spa_res_25_35,'25-35')
# No outliers
pass_to_csv("results2011_3555_T_harm",path_res,path_out = path_out)
spa_res_35_55 = pd.read_csv(path_out+"results2011_3555_T_harm.csv",index_col=0).T
spa_res_35_55 = first_format(spa_res_35_55,'35-55')


# In[581]:


format_res_table([ger_res_25_35,ger_res_35_55,spa_res_25_35,spa_res_35_55], include_sd=True)


# In[582]:


print(format_res_table([ger_res_25_35,ger_res_35_55,spa_res_25_35,spa_res_35_55], include_sd=True).to_latex(escape=False,float_format="%.3f"))


# In[583]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"
years = [2011, 2005, 1999, 1992]
tables_2535 = []
tables_3555 = []

for year in years:
    pass_to_csv("results{}_2535_T_harm".format(year),path_res,path_out = path_out)
    spa_res_2535 = pd.read_csv(path_out+"results{}_2535_T_harm.csv".format(year),index_col=0).T
    spa_res_2535 = first_format(spa_res_2535,year)
    tables_2535.append(spa_res_2535)
    
    pass_to_csv("results{}_3555_T_harm".format(year),path_res,path_out = path_out)
    spa_res_3555 = pd.read_csv(path_out+"results{}_3555_T_harm.csv".format(year),index_col=0).T
    spa_res_3555 = first_format(spa_res_3555,year)
    tables_3555.append(spa_res_3555)


# In[584]:


print(format_res_table(tables_2535+tables_3555, include_sd=True).to_latex(escape=False,float_format="%.3f"))


# In[585]:


format_res_table(tables_2535+tables_3555, include_sd=True)


# Age controls

# In[586]:


path_res = "./data/intermediate/germany/"

# Baseline decomp
pass_to_csv("031_decomp_2011",path_res)
ger_res = pd.read_csv(path_res+"031_decomp_2011.csv",index_col=0).T
ger_res = first_format(ger_res,'Baseline')
# Age controls
pass_to_csv("035_decomp",path_res)
ger_res_age = pd.read_csv(path_res+"035_decomp.csv",index_col=0).T
ger_res_age = first_format(ger_res_age,r'Age controls')


# In[587]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"

# Baseline decomp
pass_to_csv("results2011_T_harm",path_res,path_out = path_out)
spa_res_11 = pd.read_csv(path_out+"results2011_T_harm.csv",index_col=0).T
spa_res_11 = first_format(spa_res_11,'Baseline')
# Age controls
pass_to_csv("results2011_age_T_harm",path_res,path_out = path_out)
spa_res_age = pd.read_csv(path_out+"results2011_age_T_harm.csv",index_col=0).T
spa_res_age = first_format(spa_res_age,r'Age controls')


# In[588]:


print(format_res_table([ger_res,ger_res_age,spa_res_11,spa_res_age]).to_latex(escape=False,float_format="%.3f"))


# ## 4. Business Cycle Controls

# In[589]:


path_res = "./data/intermediate/germany/"

# Baseline decomp
pass_to_csv("031_decomp_2011",path_res)
ger_res = pd.read_csv(path_res+"031_decomp_2011.csv",index_col=0).T
ger_res = first_format(ger_res,'Baseline')
# GDP Growth
pass_to_csv("037_decomp_growth_unemp",path_res)
ger_res_unemp = pd.read_csv(path_res+"037_decomp_growth_unemp.csv",index_col=0).T
ger_res_unemp = first_format(ger_res_unemp,r'$\Delta$u')
# Unemployment rate change
pass_to_csv("037_decomp_real_gdp_growth",path_res)
ger_res_gdp = pd.read_csv(path_res+"037_decomp_real_gdp_growth.csv",index_col=0).T
ger_res_gdp = first_format(ger_res_gdp,r'$\Delta$GDP')


# In[590]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"

# Baseline decomp
pass_to_csv("results2011_T_harm",path_res,path_out = path_out)
spa_res_11 = pd.read_csv(path_out+"results2011_T_harm.csv",index_col=0).T
spa_res_11 = first_format(spa_res_11,'Baseline')
# Unemployment rate change
pass_to_csv("results2011_unemp_T_harm",path_res,path_out = path_out)
spa_res_unemp = pd.read_csv(path_out+"results2011_unemp_T_harm.csv",index_col=0).T
spa_res_unemp = first_format(spa_res_unemp,r'$\Delta$u')
# GDP Growth
pass_to_csv("results2011_dY_T_harm",path_res,path_out = path_out)
spa_res_gdp = pd.read_csv(path_out+"results2011_dY_T_harm.csv",index_col=0).T
spa_res_gdp = first_format(spa_res_gdp,r'$\Delta$GDP')


# In[591]:


format_res_table([ger_res,ger_res_unemp,ger_res_gdp,
                        spa_res_11,spa_res_unemp,spa_res_gdp])


# In[592]:


print(format_res_table([ger_res,ger_res_unemp,ger_res_gdp,
                        spa_res_11,spa_res_unemp,spa_res_gdp]).to_latex(escape=False,float_format="%.3f"))


# ### 4.2 Time dummies

# In[593]:


## i have commented this out as we dont use it in the paper
# path_res = "./data/intermediate/germany/"

# Year Controls
#pass_to_csv("038_decomp_yin",path_res)
#ger_res_yin = pd.read_csv(path_res+"038_decomp_yin.csv",index_col=0).T
#ger_res_yin = first_format(ger_res_yin,r'year')
# Quarter Controls
#pass_to_csv("039_decomp_qin",path_res)
#ger_res_qin = pd.read_csv(path_res+"039_decomp_qin.csv",index_col=0).T
#ger_res_qin = first_format(ger_res_qin,r'quarter')


# In[594]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"

# Year Controls
pass_to_csv("results2011_yearD_T_harm",path_res,path_out = path_out)
spa_res_yin = pd.read_csv(path_out+"results2011_yearD_T_harm.csv",index_col=0).T
spa_res_yin = first_format(spa_res_yin,r'year')
# Quarter Controls
pass_to_csv("results2011_qtD_T_harm",path_res,path_out = path_out)
spa_res_qin = pd.read_csv(path_out+"results2011_qtD_T_harm.csv",index_col=0).T
spa_res_qin = first_format(spa_res_qin,r'quarter')


# In[595]:


# NOTE: ger_res_yin / ger_res_qin are commented out above (038/039 logs not produced),
# so this diagnostic table (not part of the tex export) is disabled to let the script run.
# format_res_table([ger_res,ger_res_yin,ger_res_qin,
#                         spa_res_11,spa_res_yin,spa_res_qin])


# In[596]:


# print(format_res_table([ger_res,ger_res_yin,ger_res_qin,
#                         spa_res_11,spa_res_yin,spa_res_qin]).to_latex(escape=False,float_format="%.3f"))


# ## 5. Pure Spells

# In[597]:


path_res = "./data/intermediate/germany/"
path_res_jul = "./data/intermediate/germany/"

# Baseline decomp
pass_to_csv("031_decomp_2011",path_res)
ger_res = pd.read_csv(path_res+"031_decomp_2011.csv",index_col=0).T
ger_res = first_format(ger_res,'Germany')
# Only mini
#pass_to_csv("040_decomp",path_res)
#ger_res_mini = pd.read_csv(path_res+"040_decomp.csv",index_col=0).T
#ger_res_mini = first_format(ger_res_mini,r'Only Mini-jobs')
# Only temp
pass_to_csv("041_decomp",path_res)
ger_res_temp = pd.read_csv(path_res+"041_decomp.csv",index_col=0).T
ger_res_temp = first_format(ger_res_temp,r'Only Temporary jobs')
# Mostly mini
pass_to_csv("042_decomp",path_res_jul)
ger_res_mmini = pd.read_csv(path_res_jul+"042_decomp.csv",index_col=0).T
ger_res_mmini = first_format(ger_res_mmini,r'Mostly Mini-jobs')
# SD in levels from 05_descriptives-5.log (tabstat days, >=25% mini sample)
ger_res_mmini['sig_y'] = 299889.6
# Mostly temp
pass_to_csv("043_decomp",path_res_jul)
ger_res_mtemp = pd.read_csv(path_res_jul+"043_decomp.csv",index_col=0).T
ger_res_mtemp = first_format(ger_res_mtemp,r'Mostly Temporary jobs')
# SD in levels from 05_descriptives-5.log (tabstat days, >=25% temp sample)
ger_res_mtemp['sig_y'] = 280340.4
# Mostly unemployment
pass_to_csv("044_decomp",path_res)
ger_res_munemp = pd.read_csv(path_res+"044_decomp.csv",index_col=0).T
ger_res_munemp = first_format(ger_res_munemp,r'Mostly Unemployment')
# SD in levels from 044_decomp.log (tabstat days, >=25% unemp sample)
ger_res_munemp['sig_y'] = 193515.6


# In[598]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"

# Only T
pass_to_csv("results2011_onlyT_harm",path_res,path_out = path_out)
spa_res_t = pd.read_csv(path_out+"results2011_onlyT_harm.csv",index_col=0).T
spa_res_t = first_format(spa_res_t,r'Only Temporary Jobs')
# Only U
pass_to_csv("results2011_onlyU_harm",path_res,path_out = path_out)
spa_res_u = pd.read_csv(path_out+"results2011_onlyU_harm.csv",index_col=0).T
spa_res_u = first_format(spa_res_u,r'Only Unemployment')
# Some T (=<.45 of the spell)
pass_to_csv("results2011_someT_harm",path_res,path_out = path_out)
spa_res_mix = pd.read_csv(path_out+"results2011_someT_harm.csv",index_col=0).T
spa_res_mix = first_format(spa_res_mix,r'Mixed (<45% temp)')
# Mostly T (>.45 of the spell)
pass_to_csv("results2011_mostlyT_harm",path_res,path_out = path_out)
spa_res_mix2 = pd.read_csv(path_out+"results2011_mostlyT_harm.csv",index_col=0).T
spa_res_mix2 = first_format(spa_res_mix2,r'Mixed (>45% temp)')


# In[599]:


print(format_res_table([ger_res,ger_res_temp,
                        spa_res_11,spa_res_t], include_sd=True).to_latex(escape=False,float_format="%.3f"))


# In[600]:


print(format_res_table([ger_res_mtemp,spa_res_mix2], include_sd=True).to_latex(escape=False,float_format="%.3f"))


# In[601]:


# Disabled diagnostic (ger_res_mini / spa_res_u not defined; not part of the tex export):
# format_res_table([ger_res,ger_res_mini,ger_res_temp,
#                         spa_res_11,spa_res_t,spa_res_u], include_sd=True)


# In[602]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"
years = [2011, 2005, 1999, 1992]
tables_mixed,tables_mixed2 = [], []

for year in years:
    pass_to_csv("results{}_someT_harm".format(year),path_res,path_out = path_out)
    spa_res_mix = pd.read_csv(path_out+"results{}_someT_harm.csv".format(year),index_col=0).T
    spa_res_mix = first_format(spa_res_mix,year)
    tables_mixed.append(spa_res_mix)

    pass_to_csv("results{}_mostlyT_harm".format(year),path_res,path_out = path_out)
    spa_res_mix = pd.read_csv(path_out+"results{}_mostlyT_harm.csv".format(year),index_col=0).T
    spa_res_mix = first_format(spa_res_mix,year)
    tables_mixed2.append(spa_res_mix)


# In[603]:


print(format_res_table(tables_mixed, include_sd=True).to_latex(escape=False,float_format="%.3f"))


# In[604]:


print(pd.concat((format_res_table(tables_mixed2, include_sd=True),format_res_table(tables_mixed, include_sd=True)),axis=1).to_latex(escape=False,float_format="%.3f"))


# ## 6. Only the Slow (9 year gap)

# In[605]:


path_res = "./data/intermediate/spain/results/"
path_out = "./data/intermediate/spain/results/"

pass_to_csv("Over9years1992_T_harm",path_res,path_out = path_out)
spa_res_slow = pd.read_csv(path_out+"Over9years1992_T_harm.csv",index_col=0).T
spa_res_slow = first_format(spa_res_slow,"9-year gap")



pass_to_csv("results2011_T_harm_quits",path_res,path_out = path_out)
spa_res_quits = pd.read_csv(path_out+"results2011_T_harm_quits.csv",index_col=0).T
spa_res_quits = first_format(spa_res_quits,"Quits only")


# In[606]:


print(format_res_table((tables[-1],spa_res_slow), include_sd=True))


# In[607]:


print(format_res_table((tables[0],spa_res_quits,tables[-1],spa_res_slow), include_sd=True).to_latex(escape=False,float_format="%.3f"))


# In[608]:


print(format_res_table((tables[0],spa_res_quits,tables[-1],spa_res_slow), include_sd=True).to_latex(escape=False,float_format="%.3f"))


# ---
# ## Export: write all paper tables to `output/tables/results_tables.tex`

# In[609]:


## ── Export all paper tables to output/tables/results_tables.tex ───────────────────────
#
# NOTE: several cells reuse the names `ger_res` and `spa_res_11` with
# different column labels for different tables.  At the end of the notebook:
#   ger_res      -> Germany baseline data, label = 'Germany'  (set in cell 57)
#   spa_res_11   -> Spain   baseline data, label = 'Baseline' (set in cell 48)
# `relabel()` is used below to attach the right column header without touching
# any earlier cell.

import re

def relabel(s, name):
    """Return a copy of Series s with .name changed to `name`."""
    s = s.copy()
    s.name = name
    return s

def fix_latex(s):
    """
    Post-process a to_latex() string to match paper formatting:
      1. Escape % in row labels so they are not treated as LaTeX comments.
      2. Insert \\midrule between the sigma^2_b row and the share rows.
      3. Insert \\hline \\hline before the N row.
    """
    # 1. Escape % in known percentage-share row labels
    for row in ['constant', 'spell number', 'duration dependence',
                'heterogeneity', 'controls']:
        s = s.replace(f'% {row} &', f'\\% {row} &')

    # 2. Insert \midrule after the $\sigma^{2}_b$ row
    lines = s.split('\n')
    out = []
    for line in lines:
        out.append(line)
        if '$\\sigma^{2}_b$' in line and '&' in line:
            out.append('\\midrule')
    s = '\n'.join(out)

    # 3. Insert \hline \hline before the N row
    lines = s.split('\n')
    out = []
    for line in lines:
        if re.match(r'^N\s*&', line.strip()):
            out.append('\\hline \\hline')
        out.append(line)
    s = '\n'.join(out)

    return s

def apply_header(s, country_groups=None, col_labels=None):
    """
    Replace the auto-generated column header line with paper-format headers.

    country_groups : list of (country_name, n_cols), e.g. [('Germany',2),('Spain',2)]
                     When given, a \\multicolumn country row is inserted first.
    col_labels     : list of per-column labels for the sub-header row,
                     e.g. ['female','male','female','male'].
                     When given, this becomes the 'Variable & ... \\\\' row.

    Tables that already carry 'Germany'/'Spain' directly in the pandas header
    (tab:results_main, no-outliers) and single-country tables should NOT call
    this function.
    """
    lines = s.split('\n')
    out = []
    skip_next = False
    for line in lines:
        if skip_next:
            skip_next = False   # discard the old auto-generated column header
            continue
        out.append(line)
        if line.strip() == '\\toprule':
            skip_next = True
            # Row 1 (optional): \multicolumn country grouping
            if country_groups is not None:
                n_countries = len(country_groups)
                mc_parts = []
                for j, (country, n) in enumerate(country_groups):
                    fmt = 'c|' if j < n_countries - 1 else 'c'
                    mc_parts.append(f'\\multicolumn{{{n}}}{{{fmt}}}{{{country}}}')
                out.append(' & ' + ' & '.join(mc_parts) + ' \\\\[5pt]')
            # Row 2: per-column labels
            if col_labels is not None:
                out.append('Variable & ' + ' & '.join(col_labels) + ' \\\\')
    # Clean old latex headers
    out = [line for line in out
         if not (line.strip().startswith('Variable') and all(
             p.strip() == '' for p in line.strip().rstrip('\\').split('&')[1:]))]
    return '\n'.join(out)

def tex(tables, include_sd=False):
    """Format, convert to LaTeX, and apply paper-style fixes."""
    return fix_latex(
        format_res_table(tables, include_sd=include_sd).to_latex(escape=False, float_format="%.3f")
    )

sections = []

# ── 1. Baseline (tab:results_main) ──────────────────────────────────────────
# Columns are already labelled 'Germany' / 'Spain' — no header change needed.
# SD in levels available for both countries.
sections.append("% tab:results_main -- Baseline decomposition\n" +
    tex([relabel(ger_res, 'Germany'), relabel(spa_res_11, 'Spain')], include_sd=True))

# ── 2. Temporary contracts / mostly-temp (tab:results_mixed) ─────────────────
# Generated labels: 'Mostly Temporary jobs' / 'Mixed (>45% temp)'
# Paper labels:     'Mostly Temp'           / 'Mostly Temp'
# SD in levels available for both countries.
t = tex([ger_res_mtemp, spa_res_mix2], include_sd=True)
t = apply_header(t,
    country_groups=[('Germany', 1), ('Spain', 1)],
    col_labels=['Mostly Temp', 'Mostly Temp'])
sections.append("% tab:results_mixed -- Mostly-temporary contracts\n" + t)

# ── 3. By sex (decomp_sex) ────────────────────────────────────────────────────
t = tex([ger_res_fem, ger_res_mal, spa_res_fem, spa_res_mal], include_sd=True)
t = apply_header(t,
    country_groups=[('Germany', 2), ('Spain', 2)],
    col_labels=['female', 'male', 'female', 'male'])
sections.append("% decomp_sex -- Decomposition by sex\n" + t)

# ── 4. Business cycle controls (tab:results_spain_BC) ────────────────────────
# ger_res is currently labeled 'Germany'; relabel to 'Baseline' for this table.
# spa_res_11 is already labeled 'Baseline' (set in cell 48).
t = tex([relabel(ger_res, 'Baseline'), ger_res_unemp, ger_res_gdp,
         spa_res_11,                   spa_res_unemp, spa_res_gdp])
# Rename '% spell number' -> '% spell number and BC controls' for this table only
t = t.replace(r'\% spell number &', r'\% spell number and BC controls &')
t = apply_header(t,
    country_groups=[('Germany', 3), ('Spain', 3)],
    col_labels=['Baseline', r'$\Delta$u', r'$\Delta$GDP',
                'Baseline', r'$\Delta$u', r'$\Delta$GDP'])
sections.append("% tab:results_spain_BC -- Business cycle controls\n" + t)

# ── 5. No outliers (appendix, no label in paper) ─────────────────────────────
# Columns are already 'Germany' / 'Spain' — no header change needed.
sections.append("% Appendix: No outliers\n" +
    tex([ger_res_noout, spa_res_11_noout], include_sd=True))

# ── 6. Age groups (appendix, no label) ───────────────────────────────────────
t = tex([ger_res_25_35, ger_res_35_55, spa_res_25_35, spa_res_35_55], include_sd=True)
t = apply_header(t,
    country_groups=[('Germany', 2), ('Spain', 2)],
    col_labels=['25-35', '35-55', '25-35', '35-55'])
sections.append("% Appendix: Decomposition by age group (25-35 / 35-55)\n" + t)

# ── 7. Age controls (appendix, no label) ─────────────────────────────────────
# ger_res_age and spa_res_age were set in cells 43-44 and not overwritten.
# ger_res needs 'Baseline'; spa_res_11 is already 'Baseline'.
t = tex([relabel(ger_res, 'Baseline'), ger_res_age,
         spa_res_11,                   spa_res_age])
t = apply_header(t,
    country_groups=[('Germany', 2), ('Spain', 2)],
    col_labels=['Baseline', 'Age controls', 'Baseline', 'Age controls'])
sections.append("% Appendix: Decomposition with age controls\n" + t)

# ── 8. Education (appendix, no label) ────────────────────────────────────────
# Single-country tables — no country header needed; column labels already match.
sections.append("% Appendix: Germany -- by educational level\n" +
    tex(res_ger_edu, include_sd=True))

sections.append("% Appendix: Spain -- by educational level\n" +
    tex(res_spa_edu, include_sd=True))

# ── 9. Pure temporary spells (tab:purespells, appendix) ──────────────────────
# ger_res needs 'Baseline'; spa_res_11 is already 'Baseline'.
t = tex([relabel(ger_res, 'Baseline'), ger_res_temp,
         relabel(spa_res_11, 'Baseline'), spa_res_t], include_sd=True)
t = apply_header(t,
    country_groups=[('Germany', 2), ('Spain', 2)],
    col_labels=['Baseline', 'Only Temporary jobs',
                'Baseline', 'Only Temporary Jobs'])
sections.append("% tab:purespells -- Pure / only-temporary spells\n" + t)

# ── 10. Spain time windows (tab:results_spain_sample, appendix) ──────────────
# Spain-only, no country header. Generated labels '2011'/'2005'/'1999'/'1992'
# → paper uses 'Baseline'/'2005-'/'1999-'/'1992-'.
t = tex(tables, include_sd=True)
t = apply_header(t, col_labels=['Baseline', '2005-', '1999-', '1992-'])
sections.append("% tab:results_spain_sample -- Spain, different time windows\n" + t)


# ── 11. Spain mixed spells (tab:spain_mixed, appendix) ────────────────────
# Baseline | Mostly Temporary | Mostly Unemployment (3 columns)
# NOTE: spa_res_mix and spa_res_mix2 are stale by this point (overwritten in the time-window loop).
# We reload the 2011 files directly to ensure correct vintage.
_path_res_spa = "./data/intermediate/spain/results/"
_path_out_spa = "./data/intermediate/spain/results/"

pass_to_csv("results2011_mostlyT_harm", _path_res_spa, path_out=_path_out_spa)
_spa_mostly_t = pd.read_csv(_path_out_spa + "results2011_mostlyT_harm.csv", index_col=0).T
_spa_mostly_t = first_format(_spa_mostly_t, r'Mostly Temporary')

pass_to_csv("results2011_someT_harm", _path_res_spa, path_out=_path_out_spa)
_spa_some_t = pd.read_csv(_path_out_spa + "results2011_someT_harm.csv", index_col=0).T
_spa_some_t = first_format(_spa_some_t, r'Mostly Unemployment')

t = tex([relabel(spa_res_11, 'Baseline'), _spa_mostly_t, _spa_some_t], include_sd=True)
t = apply_header(t,
    country_groups=[('Spain', 3)],
    col_labels=['Baseline', 'Mostly Temporary', 'Mostly Unemployment'])
sections.append("% tab:spain_mixed -- Spain mixed spells\n" + t)

# ── 12. Germany time windows (tab:results_germany_sample, appendix) ──────────────
# Germany-only, no country header. Generated labels '2016/2014/2011'
tables_ger_windows = [ger_res, ger_res_2014, ger_res_2016]

t = tex(tables_ger_windows, include_sd=True)
t = apply_header(t, col_labels=['Baseline', '2014-', '2016-'])
sections.append("% tab:results_germany_sample -- Germany, different time windows\n" + t)

# ── 13. Germany mixed spells (tab:germany_mixed, appendix) ──────────────────
# Baseline | Mostly Mini | Mostly Temporary | Mostly Unemployment (4 columns)
t = tex([relabel(ger_res, 'Baseline'), ger_res_mmini, ger_res_mtemp, ger_res_munemp], include_sd=True)
t = apply_header(t,
    country_groups=[('Germany', 4)],
    col_labels=['Baseline', 'Mostly Mini', 'Mostly Temporary', 'Mostly Unemployment'])
sections.append("% tab:germany_mixed -- Germany mixed spells\n" + t)

# ── Write file ────────────────────────────────────────────────────────────────
output_tex = "./output/tables/results_tables.tex"
with open(output_tex, 'w', encoding='utf-8') as f:
    f.write("% Results Tables\n")
    f.write("% Auto-generated by 'Results_Tables.ipynb'\n")
    f.write("% Do not edit manually - re-run the notebook to update.\n\n")
    f.write("\n\n".join(sections))
    f.write("\n")

print(f"Saved {len(sections)} tables to {output_tex}")


# In[ ]:




