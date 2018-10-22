close all
clear all
clc

% Numerator
num = [1];

% Denominator
den = [[1 1], [1,1]];

% Transfer Function
G = tf(num, den)

% Bode Plot
bode(G), grid