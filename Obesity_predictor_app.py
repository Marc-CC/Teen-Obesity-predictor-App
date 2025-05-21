import streamlit as st
import pandas as pd
import numpy as np
import subprocess
import json
from tensorflow.keras.models import load_model

# Load model predictor
@st.cache_resource
def load_model_once():
    return load_model("LSTM_obesity_zbmi_predictor")
model = load_model_once()

# Define functions for later use
# Convert empty cells to None
def convert_to_none(df):
    return df.applymap(lambda x: None if isinstance(x, str) and x.strip() == "" else x)

# Process into array
def preprocess_to_3d_array(df, measure_cols, sex_cols, real_col):
    measures = df[measure_cols].values.reshape(-1, len(measure_cols), 1)
    sex = df[sex_cols].values
    sex_repeated = np.repeat(sex[:, np.newaxis, :], len(measure_cols), axis=1)
    is_real_value = df[real_col].apply(lambda x: 0 if x == "Unknown" else 1).values
    is_real_value = is_real_value.reshape(-1, 1, 1)
    is_real_value = np.repeat(is_real_value, len(measure_cols), axis=1)
    Combined_array = np.concatenate([measures, sex_repeated, is_real_value], axis=2)
    return Combined_array
    
# Define a converter function
def convert_to_label(predictions):
    labels = []
    for prediction in predictions:
        match prediction:
            case _ if prediction < -2.0:
                labels.append("Underweight")
            case _ if -2.0 <= prediction <= 1.0:
                labels.append("Normal weight")
            case _ if 1.0 < prediction <= 2.0:
                labels.append("Overweight")
            case _ if prediction > 2.0:
                labels.append("Obese")
            case _:
                labels.append(np.nan)
    return labels



st.title("_Teen Obesity predictor app_")

st.write('''
    This app uses a pre-trained machine learning model to predict the zbmi score and its label of children between the ages 2 through 13 at 14 years old.
    Please take into consideration that the prediction might not be accurate and should always be reviewed by an expert (i.e. pediatrician).
    ''')

st.header("Data input form", divider = "grey")

st.write('''
    Enter available Height (cm) and Weight (kg) data pairs between ages 2 through 13.
    Missing data pairs are handled natively by this machine learning model.
    To get the prediction click on the **Pedict** button under the next section.
    You can also upload a csv file with the correct format.
    ''')

if "child_info" not in st.session_state:
    st.session_state.child_info = pd.DataFrame(columns=["Age", "Height_cm", "Weight_kg"])

# Create select box
if "child_sex" not in st.session_state:
    st.session_state.child_sex = pd.DataFrame(columns=["Sex"])

# Create uploader and st.dataframe
uploaded_file = st.file_uploader("Upload a CSV file with columns: Age, Height_cm, Weight_kg", type=["csv"], accept_multiple_files = False)

if uploaded_file:
    try:
        uploaded_df = pd.read_csv(uploaded_file)
        required_cols = {"Age", "Height_cm", "Weight_kg"}
        if not required_cols.issubset(uploaded_df.columns):
            st.error("CSV must contain the following columns: Age, Height_cm, Weight_kg")
        else:
            uploaded_df = uploaded_df[["Age", "Height_cm", "Weight_kg"]].copy()
            uploaded_df["Age"] = uploaded_df["Age"].astype(int)
            uploaded_df["Height_cm"] = uploaded_df["Height_cm"].astype(float)
            uploaded_df["Weight_kg"] = uploaded_df["Weight_kg"].astype(float)

            uploaded_df = uploaded_df[uploaded_df["Age"].between(2, 13)].sort_values(by="Age")

            full_range = pd.DataFrame({"Age": list(range(2, 14))})
            uploaded_df = pd.merge(uploaded_df, full_range, on="Age", how="left")

            child_df = uploaded_df

    except Exception as e:
        st.error(f"Error processing file: {e}")
        child_df = pd.DataFrame({
            "Age": list(range(2, 14)),
            "Height_cm": [None] * 12,
            "Weight_kg": [None] * 12
        })
else:
    child_df = pd.DataFrame({
        "Age": list(range(2, 14)),
        "Height_cm": [None] * 12,
        "Weight_kg": [None] * 12
    })


# Selectbox for sex,
sex = st.selectbox("Enter child sex:", ["Unspecified", "Male", "Female"], index=0)
sex_if_default = sex if sex != "Unspecified" else "Male"
sex_df = pd.DataFrame({"Sex": [sex_if_default] * 12})
st.session_state.child_sex = sex_df

edited_child_df = st.data_editor(child_df,
                               use_container_width=True,
                               height=457,
                               column_config={
                                   "Age": st.column_config.NumberColumn(
                                    "Age (years)",
                                    disabled=True),
                                   "Height_cm": st.column_config.NumberColumn(
                                    "Height (cm)",
                                    min_value=40.0,
                                    max_value=200.0),
                                    "Weight_kg": st.column_config.NumberColumn(
                                        "Weight (kg)",
                                        min_value=10.0,
                                        max_value=150.0)
                                    })

# Fill child_info with edited data
st.session_state.child_info = edited_child_df.copy()

# Combine data into single df
combined_data = pd.concat([st.session_state.child_sex, st.session_state.child_info], axis=1)

combined_data = convert_to_none(combined_data)

# Convert df types
combined_data["Age"] = combined_data["Age"].astype(int)
combined_data["Height_cm"] = combined_data["Height_cm"].astype(float)
combined_data["Weight_kg"] = combined_data["Weight_kg"].astype(float)

# Add download button as csv
csv = combined_data.to_csv(index=False)
st.write('''
    You can download your data (optionally) as a CSV file by pressing the **Download** button.
    ''')
st.download_button("Download", data=csv, file_name="child_data.csv", mime="text/csv")


# Prediction
st.header("Zbmi Prediction at 14 years old")
if st.button("Predict"):
    json_data = combined_data.to_json(orient="records")
    
    with open("child_data.json", "w") as f:
        f.write(json_data)

    subprocess.run(["Rscript", "Subprocess.R"])

    with open("child_data_processed.json", "r") as f:
        processed_data = json.load(f)

    processed_data = pd.DataFrame(processed_data)

    Measure_cols_3d_array = [f"zbmi_{i}" for i in range(2, 14)]
    processed_data_3d = preprocess_to_3d_array(processed_data, Measure_cols_3d_array, ["sex_Female", "sex_Male"], "stratify")
    processed_data_3d = np.where(processed_data_3d == None, np.nan, processed_data_3d).astype(float)
    processed_data_3d = np.nan_to_num(processed_data_3d, nan=999.0)

    zbmi_prediction = model.predict(processed_data_3d)
    zbmi_label = convert_to_label(zbmi_prediction)

    st.metric(label="ZBMI Prediction", value=f"{zbmi_prediction[0][0]:.3f}")
    st.metric(label="Label predicted", value=f"{zbmi_label[0]}")