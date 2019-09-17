# This is best viewed in a Jupyter notebook
# Only reason it's in a .py instead is because my GitHub
# language analysis was saying most of the code is a notebook
# When really the code is written in Pascal and this file is not
# Look at previous versions if you want the notebook, otherwise
# this file is unchanged

# PYTHON 3
import numpy as np
import matplotlib.pyplot as plt
import scipy.signal as signal
import csv
import pandas as pd

# These functions should be considered state of the art for non-causal butterworth coefficient generation

def bw_bp_ba(lowcut, highcut, fs, order = 2):
        nyq = 0.5 * fs
        low = lowcut / nyq
        high = highcut / nyq
        b,a = signal.butter(order, [low, high], analog = False, btype = 'band', output = 'ba')
        return b, a
    
def bw_bp_sos(lowcut, highcut, fs, order = 2):
        nyq = 0.5 * fs
        low = lowcut / nyq
        high = highcut / nyq
        sos = signal.butter(order, [low, high], analog = False, btype = 'band', output = 'sos')
        return sos
        
hp = 1
lp = 30
fs = 250
order = 2
sos = bw_bp_sos(hp, lp, fs, order)
b, a = bw_bp_ba(hp, lp, fs, order) # unused
print(sos)

#https://dsp.stackexchange.com/questions/38304/iir-biquad-real-time-filter-just-output-noises
coeffs = dict(
    b0=0.08635926,
    b1=0.17271853,
    b2=0.08635926,
    a1=-1.0198188,
    a2=0.37262961,
)

coeffs2 = dict(
    b0=1.,
    b1=-2.,
    b2=1.,
    a1=-1.96457051,
    a2=0.96523025,
)

# Filters using first coefficients
def filter_process(input_data):
    zb = [0., 0.]

    output_data = []
    for data in input_data:

        output_data.append(coeffs['b0'] * data + zb[0])
        zb[0] = zb[1] + coeffs['b1'] * data - coeffs['a1'] * output_data[-1]
        zb[1] = coeffs['b2'] * data - coeffs['a2'] * output_data[-1]

    return output_data

# Filters using second coefficients
def filter_process2(input_data):
    zb = [0., 0.]

    output_data = []
    for data in input_data:

        output_data.append(coeffs2['b0'] * data + zb[0])
        zb[0] = zb[1] + coeffs2['b1'] * data - coeffs2['a1'] * output_data[-1]
        zb[1] = coeffs2['b2'] * data - coeffs2['a2'] * output_data[-1]

    return output_data

# Filters using sos (both coefficients supported using stage)
z_buff = np.array([[0.,0.],[0.,0.]])
y_buff = np.array([0.,0.])
def filter_sample_test(data, stage):
    global z_buff;
    global y_buff;
    global sos;
    y_buff[stage] = (sos[stage, 0] * data + z_buff[stage, 0])
    z_buff[stage, 0] = z_buff[stage, 1] + sos[stage, 1] * data - (sos[stage, 4] * y_buff[stage])
    z_buff[stage, 1] = sos[stage, 2] * data - (sos[stage, 5] * y_buff[stage])

    return y_buff[stage]
    
# generate a nice juicy sine wave
fs = 250;
t = 120;
f1 = 60;
f2 = 10;
dt = 1/fs; # in seconds

samples = np.linspace(0, t, int(fs*t), endpoint=False)
signals = np.sin(2 * np.pi * f1 * samples) + np.sin(2 * np.pi * f2 * samples)


# Filter sample by sample using our flexible code
z_buff = np.array([[0.,0.],[0.,0.]])
y_buff = np.array([0.,0.])
filt = []
for i in range(len(signals)):
    last_filt = filter_sample_test(signals[i], 0);
    filt.append(filter_sample_test(last_filt, 1));
    
# Filter sample by sample using two stages independently (someone else's code modified)
out = filter_process(signals)
out2 = filter_process2(out)

# Filter sample by sample forwards and reversed (non-causal filt filt)
out2_r = list(reversed(out2))
out3 =filter_process(out2_r)
out4 = list(reversed(filter_process2(out3)))

# Plot everything
plt.plot(signals[0:250]) # RAW
plt.plot(filt[0:250])   # Ollie Filter
plt.plot(out2[0:250])   # Internet filter
plt.plot(out4[0:250])   # Internet filter as filtfilt
plt.legend(['Raw', 'Ollie Filt', 'Internet Filt', 'Internet FiltFilt'])

# Export sinewave to be filtered in pascal
np.savetxt('sinewave.csv', signals, delimiter=',')

# Export sinewave in cyton format

# Create helper variables and data structures
num_cols = 16;
num_rows = signals.shape[0]
signals_8ch = np.array([signals] * 8).tolist(); # create 8channel signal (chans = cols)
df = [[0] * num_rows] * num_cols

# Populate df
#i,32,128,[x1..x8],0,0,0,mrk,time(sec)
df[0] = [x for x in range(0, num_rows)]
df[1] = [32] * num_rows
df[2] = [128] * num_rows
df[3:11] = signals_8ch
# 11, 12, 13 are 0
df[14] = ['X99'] * num_rows
df[15] = [x*dt for x in range(0, num_rows)]
df = pd.DataFrame(df).T

# Save in multifile format
for i in range(round(num_rows/5000)):
    df.loc[i*5000:(i+1)*5000, :].to_csv('60Hz10Hz_Sim_' + str(i) + '_trl.txt', index=False, header=False)
    
# Plot differences between my code and internet code
mine = np.array(filt)
theirs = np.array(out2)
plt.plot((mine-theirs)[0:250]) # magnitude e-7

# Plot Lazarus filter's output
filt_from_laz = np.genfromtxt('output_wave.csv', delimiter = ',')
filtfilt_from_laz = np.genfromtxt('filtfilt_output_wave.csv', delimiter = ',')
plt.plot(filt_from_laz[0:250])
plt.plot(filtfilt_from_laz[0:250], 'r')
plt.legend(['Filt', 'FiltFilt'])

# Plot raw and filt
plt.plot(signal[0:250], 'g', alpha = 0.5)
plt.plot(filt_from_laz[0:250], 'r')
plt.legend(['raw', 'filt'])

# Plot raw and filtfilt
plt.plot(signal[0:250], 'g', alpha=0.5)
plt.plot(filtfilt_from_laz[0:250], 'r')
plt.legend(['raw', 'filtfilt'])

# Compare Python vs Lazarus Ollie implementations
plt.plot((mine[0:250]-from_laz[0:250])) # magnitude e-14
