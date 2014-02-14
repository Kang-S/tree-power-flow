/Applications/MATLAB_R2013a.app/bin/matlab -nojvm -nosplash -nodisplay -logfile matlab.log -r "addpath('/Users/srharnett/Dropbox/power/matlab/matpower4.1'); test('$1'); exit";
#/Applications/MATLAB_R2013a.app/bin/matlab -nojvm -nosplash -nodisplay -logfile matlab.log -r test > /dev/null;
tail -n1 matlab.log 
