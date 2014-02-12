/Applications/MATLAB_R2013a.app/bin/matlab -nojvm -nosplash -nodisplay -logfile matlab.log -r "display('hi sean'); exit" > /dev/null;
tail -n1 matlab.log 
