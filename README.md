### ELK
Elasticsearch是个开源分布式搜索引擎，提供搜集、分析、存储数据三大功能。它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等。

Logstash 主要是用来日志的搜集、分析、过滤日志的工具，支持大量的数据获取方式。一般工作方式为c/s架构，client端安装在需要收集日志的主机上，server端负责将收到的各节点日志进行过滤、修改等操作在一并发往elasticsearch上去。

Kibana 也是一个开源和免费的工具，Kibana可以为 Logstash 和 ElasticSearch 提供的日志分析友好的 Web 界面，可以帮助汇总、分析和搜索重要数据日志。

```
docker-compose logs
```

```
volumes:
  - /usr/share/logstash:/usr/share/logstash
  - /var/log/nginx:/var/log/nginx
```

`vim /usr/share/logstash/conf.d/logstash.conf`
`vi /usr/share/logstash/config/logstash.conf`
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

- **重启logstash**
`logstash -f /usr/share/logstash/config/logstash.conf`
> 启动报错，无法启动logstash。
> 原因是logstash存在缓存区，进入data目录中，通过 ls -alh 查找隐藏文件.lock，rm .lock删除此文件

- 关闭logstash
`logstash -f /usr/share/logstash/config/logstash-sample.conf --config.test_and_exit`
- **`--config.reload.automatic`选项启用自动配置重新加载，因此您不必在每次修改配置文件时停止并重新启动Logstash**
`logstash -f /usr/share/logstash/config/logstash.conf --config.reload.automatic`


### 多主机ELK系统搭建
切换到 Swarm 模式，并创建一个新的 Swarm，将自身设置为 Swarm 的第一个管理节点
```
docker swarm init
```

列出群组中的节点
```
docker node ls
```

```
docker stack deploy -c docker-compose.yaml elk
```

```
docker service ls
```

```
docker service logs elk_elasticsearch -f
```

```
docker stack rm elk
```

### 参考文档
[logstash收集nginx日志](https://www.jianshu.com/p/cd41349c7e67)
[https://github.com/deviantony/docker-elk](https://github.com/deviantony/docker-elk)
[https://docs.docker.com/compose/compose-file/compose-file-v3/](https://docs.docker.com/compose/compose-file/compose-file-v3/)
[Ubuntu 16.04安装Java JDK8](https://blog.csdn.net/u012707739/article/details/78489833)


### 报错
```
ERROR: [1] bootstrap checks failed
[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```
> https://www.elastic.co/guide/en/elasticsearch/reference/7.12/docker.html

参考以上官方文档，执行如下设置：
```
grep vm.max_map_count /etc/sysctl.conf
sysctl -w vm.max_map_count=262144
sysctl -p
```

```
[ERROR][org.logstash.Logstash    ] java.lang.IllegalStateException: org.jruby.exceptions.RaiseException: (SystemExit) exit
```
volumes绑定错误


```
Unrecognized VM option 'UseParNewGC'
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
```
```
sudo vim /var/lib/docker/volumes/single_node_elk_logstash/_data/config/jvm.options
```
注释掉`-XX:+UseParNewGC`

```
[ERROR][org.logstash.Logstash    ] java.lang.IllegalStateException: org.jruby.exceptions.RaiseException: (LoadError) Unsupported platform: x86_64-linux
```
排查一下文件写入的文件夹是否是可写的。
https://discuss.elastic.co/t/logstash-configuration-file-is-not-working-its-giving-error/119911

```
[2021-05-10T04:07:50,333][FATAL][logstash.runner          ] Logstash could not be started because there is already another instance using the configured data directory.  If you wish to run multiple instances, you must change the "path.data" setting.
[2021-05-10T04:07:50,353][ERROR][org.logstash.Logstash    ] java.lang.IllegalStateException: Logstash stopped processing because of an error: (SystemExit) exit
```