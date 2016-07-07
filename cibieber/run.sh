echo "welcome to the CI script at `pwd`"

python runner.py run-all
python runner.py do-pullrequests
python runner.py render
rsync -az results.html logs/ timo.ces:public_html/cib/dealii-tester-alpha/

echo "exiting."
