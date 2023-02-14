ARG elastic_v=7.17.8
FROM elasticsearch:${elastic_v}
WORKDIR /usr/share/elasticsearch
RUN ./bin/elasticsearch-plugin install analysis-icu
RUN ./bin/elasticsearch-plugin install analysis-kuromoji
RUN ./bin/elasticsearch-plugin install analysis-smartcn
RUN ./bin/elasticsearch-plugin install analysis-stempel