%% Compute FFT
%--------------------------------------------------------------------------
% [ output_data, output_f ] = spectr( input_data, Fs, frequencRange )
%
% Inputs:
% 1. 'input_data' - data inputs, either a vector or a matrix. If it is a
%                   matrix, treat each column as one signal.
% 2. 'Fs' - Sampling frequency, a scalar.
%
% Optional inputs:
% 3. 'frequencRange' - Frequenc range must be a 1-by-2 vector: [min, max].
%
% Outputs:
% 1. 'output_data' - complex one-sided spectrum of the input signals.
% 2. 'output_f' - frequency axis (right-half plane).
%--------------------------------------------------------------------------
function [ output_data, output_f] = spectr2(input_data, Fs)
% Author: Yitian Shao
% Created on 05/01/2017 based on 'powerSpectrum.m'
%==========================================================================
dim1 = size(input_data,1); % Data row number
if dim1==1
    L = length(input_data); % Row vector input
    input_data = input_data';
else
    L = size(input_data,1); % Matrix input: treat each column as one signal
end

NFFT = 2^nextpow2(L); % Next power of 2 from length of y
bin_num = NFFT/2+1; % FFT bin number (right-half plane)
%==========================================================================
%Y_fft = fft(input_data,NFFT) * (1/Fs); % FFT 
Y_fft = fft(input_data,NFFT) / L; % FFT 

f = Fs/2*linspace(0,1,bin_num); % Frequency scale

Y_fft = Y_fft(1:bin_num,:); %complex one-sided spectrum

%TODO: add in tolerance value?
%phi = atan2(imag(Y_fft(1:bin_num)),real(Y_fft(1:bin_num)));

% No truncation, return entire frequency band
output_data = Y_fft; % Test all fft
output_f = f;

end
