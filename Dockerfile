FROM python:3.11.12-slim

# Install R
RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base r-base-dev \
    libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev \
    libpng-dev libtiff5-dev libjpeg-dev libglib2.0-dev libssh2-1-dev \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages(c('jsonlite', 'dplyr', 'tidyr', 'growthcleanr', 'anthro', 'anthroplus'), repos='https://cran.r-project.org')"

WORKDIR /CODE_TFM

COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8501

CMD ["streamlit", "run", "Obesity_predictor_app.py", "--server.port=8501", "--server.enableCORS=false"]
