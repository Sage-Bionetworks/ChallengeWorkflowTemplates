FROM python:3.6

RUN pip install git+https://github.com/Sage-Bionetworks/challengeutils.git

COPY bin/*.py /usr/local/bin/
RUN chmod a+x /usr/local/bin/*.py
