function [amplitude] = computeTransferFuncAmp(vel_signal, force_signal, vel_fs, force_fs,freq)

    vel_fft = fft_interp(vel_signal,vel_fs,freq);
    force_fft = fft_interp(force_signal,force_fs,freq);

    amplitude = vel_fft./force_fft;

end