import streamlit as st
import pandas as pd
import numpy as np
import subprocess
import json
from tensorflow.keras.models import load_model


st.title("_Teen Obesity predictor app_")

st.write("This app uses a pre-trained machine learning model to predict the zbmi score and its label of children between the ages 2 through 13 at 14 years old." \
"Please take into consideration that the prediction might not be accurate and should always be reviewed by an expert (i.e. pediatrician).")

st.header("Data input form", divider = "grey")

st.subheader("Enter available Height (cm) and Weight (kg) data between ages 2 through 13.")

if "child_info" not in st.session_state:
    st.session_state.child_info = pd.DataFrame(columns=["Age", "Height_cm", "Weight_kg"])

# Create select box
if "child_sex" not in st.session_state:
    st.session_state.child_sex = pd.DataFrame(columns=["Sex"])

# Selectbox for one age only per submission
sex = st.selectbox("Enter child sex:", ["Unspecified", "Male", "Female"], index=0)
sex_if_default = sex if sex != "Unspecified" else "Male"
sex_df = pd.DataFrame({
        "Sex": [sex_if_default] *12
        })
st.session_state.child_sex = sex_df

# Create st.dataframe
Age = list(range(2, 14))
Height_cm = [None] * len(Age)
Weight_kg = [None] * len(Age)

child_df = pd.DataFrame({"Age": Age,
                       "Height_cm": Height_cm,
                       "Weight_kg": Weight_kg
                       })

edited_child_df = st.data_editor(child_df,
                               use_container_width=True,
                               height=457,
                               column_config={
                                   "Age": st.column_config.NumberColumn(disabled=True)
                                   })

# Convert df types
edited_child_df["Age"] = edited_child_df["Age"].astype(int)
edited_child_df["Height_cm"] = edited_child_df["Height_cm"].astype(float)
edited_child_df["Weight_kg"] = edited_child_df["Weight_kg"].astype(float)

# Fill child_info with edited data
st.session_state.child_info = edited_child_df.copy()

# Add Download button and combine data into single df
combined_data = pd.concat([st.session_state.child_sex, st.session_state.child_info], axis=1)
csv = combined_data.to_csv(index=False)
st.write("Download child data as CSV file (optional to keep your data)")
st.download_button("Download", data=csv, file_name="child_data.csv", mime="text/csv")

st.header("Zbmi Prediction at 14 years old")
if st.button("Predict"):
    json_data = combined_data.to_json(orient="records")
    
    with open("child_data.json", "w") as f:
        f.write(json_data)

    subprocess.run(["Rscript", "Subprocess.R"])

    with open("child_data_processed.json", "r") as f:
        processed_data = json.load(f)

    processed_data = pd.DataFrame(processed_data)

    model = load_model("GRU_obesity_zbmi_predictor")

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
                    labels.append("Normal_weight")
                case _ if 1.0 < prediction <= 2.0:
                    labels.append("Overweight")
                case _ if prediction > 2.0:
                    labels.append("Obese")
                case _:
                    labels.append(np.nan)
        return labels

    Measure_cols_3d_array = [f"zbmi_{i}" for i in range(2, 14)]
    processed_data_3d = preprocess_to_3d_array(processed_data, Measure_cols_3d_array, ["sex_Female", "sex_Male"], "stratify")
    processed_data_3d = np.where(processed_data_3d == None, np.nan, processed_data_3d).astype(float)
    processed_data_3d = np.nan_to_num(processed_data_3d, nan=999.0)

    zbmi_prediction = model.predict(processed_data_3d)
    zbmi_label = convert_to_label(zbmi_prediction)

    st.write("Zbmi prediction: ", zbmi_prediction[0][0])
    st.write("Label predicted: ", zbmi_label)