# Full sequential lstm model
seq_lstm_full_model = tf.keras.models.Sequential()
seq_lstm_full_model.add(tf.keras.layers.Input(shape=(12, 4)))
seq_lstm_full_model.add(tf.keras.layers.Masking(mask_value=999.0))
seq_lstm_full_model.add(tf.keras.layers.LSTM(64))
seq_lstm_full_model.add(tf.keras.layers.Dense(1, activation='linear'))
seq_lstm_full_model.compile(optimizer='adam', loss='mae', metrics=['mae'])

# Reduced sequential lstm model
seq_lstm_reduced_model = tf.keras.models.Sequential()
seq_lstm_reduced_model.add(tf.keras.layers.Input(shape=(12, 4)))
seq_lstm_reduced_model.add(tf.keras.layers.Masking(mask_value=999.0))
seq_lstm_reduced_model.add(tf.keras.layers.LSTM(64))
seq_lstm_reduced_model.add(tf.keras.layers.Dense(1, activation='linear'))
seq_lstm_reduced_model.compile(optimizer='adam', loss='mae', metrics=['mae'])

# Full GRU model
gru_full_model = tf.keras.models.Sequential()
gru_full_model.add(tf.keras.layers.Input(shape=(12, 4)))
gru_full_model.add(tf.keras.layers.Masking(mask_value=999.0))
gru_full_model.add(tf.keras.layers.GRU(64))
gru_full_model.add(tf.keras.layers.Dense(1, activation='linear'))
gru_full_model.compile(optimizer='adam', loss='mse', metrics=['mae'])

# Reduced GRU model
gru_reduced_model = tf.keras.models.Sequential()
gru_reduced_model.add(tf.keras.layers.Input(shape=(12, 4)))
gru_reduced_model.add(tf.keras.layers.Masking(mask_value=999.0))
gru_reduced_model.add(tf.keras.layers.GRU(64))
gru_reduced_model.add(tf.keras.layers.Dense(1, activation='linear'))
gru_reduced_model.compile(optimizer='adam', loss='mse', metrics=['mae'])