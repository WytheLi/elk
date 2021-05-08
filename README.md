### ELK
Elasticsearch是个开源分布式搜索引擎，提供搜集、分析、存储数据三大功能。它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等。

Logstash 主要是用来日志的搜集、分析、过滤日志的工具，支持大量的数据获取方式。一般工作方式为c/s架构，client端安装在需要收集日志的主机上，server端负责将收到的各节点日志进行过滤、修改等操作在一并发往elasticsearch上去。

Kibana 也是一个开源和免费的工具，Kibana可以为 Logstash 和 ElasticSearch 提供的日志分析友好的 Web 界面，可以帮助汇总、分析和搜索重要数据日志。

```
volumes:
  - /usr/share/logstash:/usr/share/logstash
  - /var/log/nginx:/var/log/nginx
```

`vim /usr/share/logstash/conf.d/logstash.conf`
```
input {
   file {
        type => "nginx-access-log"
        path => "/var/log/nginx/access.log"
        start_position => "beginning"
        stat_interval => "2"
        codec => json
   }

}
filter {}
output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    #index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
    index => "logstash-nginx-access-log-%{+YYYY.MM.dd}"
    #user => "elastic"
    #password => "changeme"
  }
  stdout {
        codec => json_lines
  }
}
```
- start_position 指从文件开始位置读取
- stat_interval 指每间隔两秒读取一次
- index 指定索引名称
- user | password 这里没有安装xpack插件，所以用户名，密码不用配置，如果需要可以 自行配置


### 参考文档
[logstash收集nginx日志](https://www.jianshu.com/p/cd41349c7e67)
