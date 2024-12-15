# 系统监控｜Grafana+Prometheus实践

- [X]  在Linux中使用，node-exporter监控宿主机，而不是容器内
- [X]  补充文件挂载信息，Grafana数据持久化
- [ ]  补充文件挂载信息，Prometheus数据持久化
- [ ]  监控更多中间件以及服务，mysql、redis、rabbitmq等
- [ ]  自定义监控微服务业务指标

## 前置要求

操作系统：

- 开发环境：MacOS Windows
- 生产环境：Linux

容器支持：

- Docker
- Docker compose

## 项目启动

### Quick Start

> 本小节内容与操作系统无关，无需修改任何配置，快速启动和体验grafana和prometheus

克隆项目

```shell
# GitHub
git clone https://github.com/xiaolinstar/docker-prometheus.git
# Gitee
git clone https://gitee.com/xingxiaolin/docker-prometheus.git
```

进入项目目录

```shell
cd docker-prometheus
```

使用`docker compose`启动项目，默认指定`docker-compose.yaml`为容器集合启动配置

```shell
docker compose up -d
```

其他`docker compose`命令

```shell
# 容器启动，以后台方式
docker compose up -d
# 容器卸载
docker compose down

# 容器启动
docker compose start
# 容器停止
docker compose stop
```

当不再使用时，可进行容器卸载`down`，完全删除所启动的容器集合。
短暂不使用容器，则使用`start`和`stop`

### 项目结构

```
.
├── README.md # 项目说明
├── docker-compose.yaml # docker-compose配置文件
└── prometheus.yml # prometheus配置文件，需要挂在到prometheus容器中
```

### 访问

#### 检查Prometheus数据

Web浏览器中输入`http://localhost:9090/targets`

查看数据源状态，效果如下：

![prometheus-targets](assets/prometheus-targets.png)

配置文件`prometheus.yml`中`scrape_configs`包含`prometheus`和`node-exporter`两个数据源

可以查看到`Status`状态为`UP`，表示数据源正常

#### 配置Grafana

浏览器中输入`http://localhost:9080`，使用账号密码`admin/admin`登录`grafana web`，账户密码可在`docker-compose.yaml`中自定义设置。

**添加数据源**

Connection -> Data Source -> Add new data source -> Prometheus -> Settings

![datasource](assets/prometheus-datasources.png)

![prometheus-url](assets/prometheus-url.png)

输入的地址为`prometheus-url`为`http://prometheus-demo:9090`

下拉并点击`Save & Test`

![save-test](assets/datasource-success.png)

**导入dashboard**

回到`grafana web`首页，执行 Dashboards -> New -> Import

导入`Node Exporter Full`模板，ID为`1860`，然后点击`Load`

![import-dashboard](assets/import1860.png)

选择数据源为上一步骤中配置的数据源`prometheus`

操作成功效果如下：

![node-exporter-full](assets/node-exporter-dashboard.png)

右上角`Refresh`按钮可以刷新数据，右侧可以调整刷新周期

### 深入配置：Node-Exporter监控宿主机

> 网络上大多数相关教程使用二进制可执行程序启动服务，而在上一小节Quick Start中，grafana prometheus node-exporter三个服务均使用docker启动。
>
> 这会产生一个问题：node-exporter监控的是容器本身，而不是宿主机，因此本小节尝试使用node-exporter容器监控宿主机，并最小化配置修改，达到最高可移植性。

```mermaid
mindmap
    Docker网络模式
        bridge 【默认模式】，网桥上容器共享Network Namespace，可通过端口映射与宿主机连通
        host 容器和宿主机共享Network Namespace，容器映射到宿主机
        container 容器直连，显示声明容器间连通性
        none 隔离，不配置网络

```

Docker网络模式中默认且最常用的是`bridge`，其次是`host`类似于在宿主机上启动二进制服务。

本小节将`node-exporter`容器以`host`模式启动，使得作用域为宿主机，而`grafana`和`prometheus`是宿主机无关的，使用网桥模式启动以保持隔离性。

---

**切换到分支ne-host（Linux）**

> 本分支必须在Linux系统中启动，如阿里云服务器、腾讯云服务器等

> Git是版本控制工具，可以在分支中维护多种代码，在分支中切换不同版本，而不需要修改任何代码。

> 注意：在切换分支前，请先down卸载Quick Start中的容器，否则会冲突

切换到分支`ne-host`

```shell
git checkout ne-host
```

服务启动

```shell
docker compose up -d
```

整体流程与上述Quick Start一致，只是将`node-exporter`容器以`host`模式启动，而`prometheus`和`grafana`使用网桥模式启动。

此分支中可实现`node-exporter`监控Linux宿主机。

可查看CPU数量，内存容量已验证仪表盘信息。

### 技术补充

> 上述两种方式分别为QuickStart和node-exporter监控宿主机，本小节讨论监控技术细节。

项目目录下`prometheus.yml`为Prometheus配置文件，其中`scrape_configs`为数据源配置，`static_configs`为数据源地址配置。

更多内容参考：https://hulining.gitbook.io/prometheus/prometheus/configuration/configuration

与项目相关的两个文件为：`docker-compose.yaml`和`prometheus.yml`。

`docker-compose.yaml`支持多容器启动，本项目中包含三个容器：grafana、prometheus和node-exporter。

在QuickStart中，三个容器均以`bridge`模式启动，且连接在同一网桥中。在bridge模式下，各容器间可直接根据**容器名**进行访问。

相应地，在`main`分支下，`prometheus.yml`的targets为`prometheus-demo:9090`和`node-exporter-demo:9100`，即`prometheus`和`node-exporter`容器名。

---

在ne-host分支中，唯一差别是`node-exporter-demo`容器以host模式启动，因此`prometheus.yml`的targets为`172.17.0.1:9100`。

在Linux宿主机中，`172.17.0.1`为docker网桥地址，`prometheus-demo`容器可以通过`172.0.0.1`访问到宿主机的环回地址`localhost`。同时，`node-exporter-demo`服务映射在本地9100端口，因此`prometheus-demo`容器可以通过`172.0.0.1:9100`访问到`node-exporter-demo`容器。

⚠️注意，Docker中网络连通规则：

1. 同一网桥上的容器，互相之间通过**容器名**访问;
2. 容器访问宿主机：通过`172.17.0.1`桥接访问到宿主机`localhost`
3. `Docker Desktop`中以`host.docker.internal`访问宿主机，功能与2重复，但在Linux宿主机中不支持（本人在此问题上花费了较多时间，百思不得其解）
4. 容器在没有端口映射到情况下，宿主机无法访问到容器

## Prometheus数据持久化

> 时序数据可以存储在本地local，也可以通过网络存储在远程设备上以支持高可用，本小节讨论数据持久化。

node-exporter挂载根目录/，而不只是挂载/proc和/sys，虽然这两个目录已经可以获取大多数信息。

为了提高系统安全性，可以设置对宿主机系统的目录时只读的read only

远程连接第三方数据库选择：

- PostgreSQL
- influxDB
- Cassandra
- ElasticSearch

对比性能、免费、集成功能、活跃度等选择influxDB

新的问题：
prometheus remote_write原生支持influxDB v1
而不原生支持influxDB v2，需要安装第三方中间件：

- Telegraf
- Prometheus-InfluxDB Bridge
- Mimir MinIO

## Grafana Provisoning

> 本章节提供2个Git仓库：gf-provision, gf-provision-mysql，均为Grafana配置及数据持久化，后者使用mysql托管内嵌sqlite3。

登陆`Grafana UI`的账户密码，设置数据源`datasource`，新建仪表盘`dashboards`，这些数据都存储在哪里，这些应用数据
如何在不同设备之间迁移？

### Grafana配置洞察

> 从容器启动层面扒一扒所有相关参数

**环境变量**

进入启动的`grafana`容器内，执行`printenv`，打印`grafana`所有环境变量

```shell
GF_PATHS_HOME=/usr/share/grafana
HOSTNAME=4ff584f7c978
SHLVL=1
HOME=/home/grafana
OLDPWD=/var/lib/grafana
GF_PATHS_LOGS=/var/log/grafana
GF_PATHS_PROVISIONING=/etc/grafana/provisioning
TERM=xterm
GF_PATHS_PLUGINS=/var/lib/grafana/plugins
PATH=/usr/share/grafana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false
GF_SECURITY_ADMIN_USER=admin
GF_PATHS_CONFIG=/etc/grafana/grafana.ini
GF_PATHS_DATA=/var/lib/grafana
PWD=/var/lib/grafana/plugins
TZ=Asia/Shanghai
```

**配置解析**

Linux操作系统中的命名习惯，`/etc`存放配置，`/var`存放数据，`/usr`存放程序，下面列举出所有与用户配置相关的文件和目录。

> 运维开发人员按需关注下述表格中的内容


| 类型 | 名称         | 变量名称              | 位置                      | 文件类型 | 描述              |
| ---- | ------------ | --------------------- | ------------------------- | -------- | ----------------- |
| 配置 | grafana.ini  | GF_PATHS_CONFIG       | /etc/grafana/grafana.ini  | 文本文件 | Grafana初始化配置 |
|      | provisioning | GF_PATHS_PROVISIONING | /etc/grafana/provisioning | 目录     | 主动配置          |
| 数据 | data         | GF_PATHS_DATA         | /var/lib/grafana          | 目录     | Grafana数据       |
|      | plugins      | GF_PATHS_PLUGINS      | /var/lib/grafana/plugins  | 目录     | Grafana插件       |
| 日志 | logs         | GF_PATHS_LOGS         | /var/log/grafana          | 目录     | Grafana日志       |

环境变量可以在`docker-compose.yaml`的启动参数`environment`中指定，建议不要改动。

**服务启动参数**
服务的二进制启动文件一般（基本全部）包含自身服务名，可以查看容器内服务启动参数，执行命令

> 下述指令模板需要牢记，ps -ef | grep NAME

> NAME无需与查询目标完全对应，该方式为模糊匹配

```shell
ps -ef | grep grafana
```

输出信息如下(格式化后)：

```shell
grafana server --homepath=/usr/share/grafana 
  --config=/etc/grafana/grafana.ini 
  --packaging=docker 
  cfg:default.log.mode=console 
  cfg:default.paths.data=/var/lib/grafana 
  cfg:default.paths.logs=/var/log/grafana 
  cfg:default.paths.plugins=/var/lib/grafana/plugins 
  cfg:default.paths.provisioning=/etc/grafana/provisioning
```

启动参数可以在`docker-compose.yaml`的启动参数`command`中指定，建议不要改动。

**服务启动配置文件加载**

执行`docker logs CONTAINER`查看`grafana.log`文件，如下所示

![grafana-log](assets/grafana-log.png)

> 可以进到容器中，查看default.ini和grafana.ini，发现grafana.ini是加了注释到default.ini

容器启动时先读取默认初始化配置`/usr/share/grafana/conf/default.ini`，然后读取`/etc/grafana/grafana.ini`，后者会合并（或覆盖）前者配置。

默认情况下，`provisioning`配置目录是空的，这个在后面章节介绍。

### Grafana关系型数据存储

`Grafana`所有应用数据
都存储在关系数据库中，数据库默认为：`sqlite3`，数据库名称为`grafana.db`，存储在`/var/lib/grafana`目录下。

`Grafana`应用数据
可以存储在关系型数据库中，官方推荐`mysql`, `postgres`或`sqlite3`，下面介绍通过配置`grafana.ini`并使用`mysql`接管数据库存储。

> mysql适合Web应用开发；postgres更适合具有频繁写入操作和复杂查询的企业级应用程序；sqlite3为内嵌数据库，适合Android和iOS手机app；
>
> mysql是最流行的开源关系型数据库，应用最为广泛。

#### 配置文件grafana.ini

数据库相关配置位于`[database]`下，默认是注释掉的，手动修改如下：

```editorconfig
#################################### Database ####################################
[database]
# You can configure the database connection by specifying type, host, name, user and password
# as separate properties or as on string using the url properties.

# Either "mysql", "postgres" or "sqlite3", it's your choice
type = mysql
host = grafana-mysql-demo
port = 3306
name = my_grafana
user = admin_grafana
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
password = password_grafana
# Use either URL or the previous fields to configure the database
# Example: mysql://user:secret@host:port/database
url = mysql://admin_grafana:password_grafana@grafana-mysql-demo:3306/my_grafana

# Max idle conn setting default is 2
max_idle_conn = 2

# Max conn setting default is 0 (mean not set)
max_open_conn = 0

# Connection Max Lifetime default is 14400 (means 14400 seconds or 4 hours)
conn_max_lifetime = 14400
```

#### 创建mysql数据库

根据上一节配置文件信息，创建数据库`my_grafana`，授权用户`admin_grafana`，密码为`password_grafana`。

在`docker-compose.yaml`中配置`mysql`数据库，容器名为`grafana-mysql-demo`，在`mysql`启动时作初始化。

> grafana容器依赖于mysql容器，所以需要先启动mysql容器并完成初始化后，再启动grafana容器，否则会导致grafana容器启动失败。

`mysql`创建数据库`my_grafana`，并授予`admin_grafana`所有权限：

```sql
# 创建数据库grafana
CREATE DATABASE my_grafana DEFAULT CHARACTER SET utf8mb4;

# 创建用户
CREATE USER 'admin_grafana'@'%' IDENTIFIED BY 'password_grafana';

# 权限授予（使用更安全的方式管理密码）
GRANT ALL PRIVILEGES ON my_grafana.* TO 'admin_grafana'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

使用`docker compose`命令启动容器集群：

```shell
# git checkout gf-provision-mysql
docker compose up -d
```

![docker-prometheus](assets/docker-prometheus.png)

`mysql`数据库端口`3306`暴露到本地`localhost`，使用`IDEA`右端数据库插件可登录查看，使用用户名`admin_grafana`，密码`password_grafana`登陆。

![grafana-mysql](assets/grafana-mysql.png)

此时已经接管数据库`grafana.db`存储，所有的落库操作都可以在数据库中查询到，可以关注`dashboard`和`data_source`表。

### Grafana Provisioning，主动配置与版本管理

`Grafana Provisioning`支持通过配置文件的方式支持`datasources`、`dashboards`、`plugins`、`Alerting rules`等功能。

对于`Grafana`新手来说，`Provisioning`是一个比较新的概念，需要花点时间去理解，我通过引入几个简单问题来介绍`Grafana Provisioning`。

#### 问题1：如何实现Grafana仪表盘的迁移？

作为一名运维开发人员，在`Grafana UI`辛辛苦苦手动配置了数十个仪表盘，以及数百个Panel，所有的数据都存储在开发环境中。

现在需要将仪表盘迁移到生产环境中，如何实现？

公司招聘了1名新员工，来协助我完成这项工作，如何将已有工作迁移给新员工？

`Grafana`的所有数据都存储在关系型数据库`grafana.db`中，包括仪表盘、数据源、用户、权限、插件等。

**方案一：数据库全量迁移**

使用上一章节内容，在启动`Grafana`容器的时候，不使用内置`sqlite3`，而主动托管`grafana.db`数据库。

与数据库迁移类似，将`grafana.db`文件拷贝到新的环境中，即可完成仪表盘迁移，详细过程可参考「`mysql`数据库迁移」

缺陷：操作复杂笨重，且全量数据库迁移，安全性低，很多用户私有数据一同被迁移。

**方案二：描述文件迁移**

在`grafana.db`中，仪表盘描述文件是以`json`格式存储的，所以可以很方便的通过`json`文件进行导出和导入。

在`Grafana`容器启动后，手动在`Grafana UI`中导入`dashboard.json`，这依赖于手工操作，需要制定合理的制度规范。

---

> 在程序员的世界中，手工操作是可耻的，遵行宗旨：尽可能自动化一切手工操作。

`Grafana Provisioning`提供了更好的解决方式，既不直接操作数据库，也不需要手动迁移`dashboards`，可迁移性较好。

#### 问题2：如何实现仪表盘的版本管理？

`Grafana`仪表盘配置是一个长期工作，会随着需求的变化而更新，因此需要支持像源代码一样的版本管理。

`Grafana`在仪表盘修改中支持了[版本管理](https://grafana.org.cn/docs/grafana/latest/dashboards/build-dashboards/manage-version-history/)，通过版本管理，可以随时回滚到之前版本，也可以方便查看变更历史。

> Grafana UI中的版本管理是dashboard级别的，而用户更新是panel级别的

![settings-versions](assets/settings-versions.png)

`Grafana`仪表盘的版本管理有局限性：

- 版本零碎：`Grafana`版本修改是仪表盘级别的，修改仪表盘内的任何一个`panel`，将会产生一个版本，这样会产生大量的版本。
- 操作风险：版本管理仅限于`dashboard`中的`panel`等信息，如果数据源或数据格式已经发生变化，回滚版本可能无法正常工作。
- 协作困难：以某个版本为基准，多个人同时修改，合并困难且容易产生冲突。

理想情况是`Grafana`数据可以像源代码一样使用`Git`追踪和管理，并在类似于`GitLab`或`GitHub`一样托管源代码，并支持CI/CD。

`Grafana Provisioning`一定程度上提供了这个能力。

#### Grafana Provisioning介绍与实践

> Grafana has an active provisioning system that uses configuration files. This makes GitOps more natural since data sources and dashboards can be defined using files that can be version controlled.
>
> Grafana 有一个使用配置文件的主动配置系统。使用可进行版本控制的文件来定义数据源和仪表板，这使得 GitOps 更加自然。

> 在Provision Grafana官方文档页面，有关于Provisioning的详细参数定义文档，在此不做知识搬运式描述。
>
> 下面将配置数据源datasource和dashboard的方式快速体验。

##### 数据源datasources

在容器中查看`provisioning-datasources`示例`sample.yaml`，位置`/usr/share/grafana/conf/provisioning/datasources/sample.yaml`

```yaml
# Configuration file version
apiVersion: 1

# # List of data sources to delete from the database.
# deleteDatasources:
#   - name: Graphite
#     orgId: 1

# # List of data sources to insert/update depending on what's
# # available in the database.
# datasources:
#   # <string, required> Sets the name you use to refer to
#   # the data source in panels and queries.
#   - name: Graphite
#     # <string, required> Sets the data source type.
#     type: graphite
#     # <string, required> Sets the access mode, either
#     # proxy or direct (Server or Browser in the UI).
#     # Some data sources are incompatible with any setting
#     # but proxy (Server).
#     access: proxy
#     # <int> Sets the organization id. Defaults to orgId 1.
#     orgId: 1
#     # <string> Sets a custom UID to reference this
#     # data source in other parts of the configuration.
#     # If not specified, Grafana generates one.
#     uid: my_unique_uid
#     # <string> Sets the data source's URL, including the
#     # port.
#     url: http://localhost:8080
#     # <string> Sets the database user, if necessary.
#     user:
#     # <string> Sets the database name, if necessary.
#     database:
#     # <bool> Enables basic authorization.
#     basicAuth:
#     # <string> Sets the basic authorization username.
#     basicAuthUser:
#     # <bool> Enables credential headers.
#     withCredentials:
#     # <bool> Toggles whether the data source is pre-selected
#     # for new panels. You can set only one default
#     # data source per organization.
#     isDefault:
#     # <map> Fields to convert to JSON and store in jsonData.
#     jsonData:
#       # <string> Defines the Graphite service's version.
#       graphiteVersion: '1.1'
#       # <bool> Enables TLS authentication using a client
#       # certificate configured in secureJsonData.
#       tlsAuth: true
#       # <bool> Enables TLS authentication using a CA
#       # certificate.
#       tlsAuthWithCACert: true
#     # <map> Fields to encrypt before storing in jsonData.
#     secureJsonData:
#       # <string> Defines the CA cert, client cert, and
#       # client key for encrypted authentication.
#       tlsCACert: '...'
#       tlsClientCert: '...'
#       tlsClientKey: '...'
#       # <string> Sets the database password, if necessary.
#       password:
#       # <string> Sets the basic authorization password.
#       basicAuthPassword:
#     # <int> Sets the version. Used to compare versions when
#     # updating. Ignored when creating a new data source.
#     version: 1
#     # <bool> Allows users to edit data sources from the
#     # Grafana UI.
#     editable: false
```

定义`prometheus-demo`数据源，命名为`prometheus-datasource.yaml`

```yaml
apiVersion: 1
datasources:
  - name: prometheus
    type: prometheus
    access: proxy
    url: http://prometheus-demo:9090
    user:
    password:
    isDefault: true
```

##### 仪表盘dashboard

与`datasources`不同的是，`dashboards`由两层结构：

1. 在`/etc/grafana/provisioning/dashboards`下定义`dashboards`配置文件，其中指明`dashboard`目录，推荐为`/var/lib/grafana/dashboards`
2. 在`/var/lib/grafana/dashboards`目录下存放`dashboard`描述文件，格式为`json`，可由`Grafana UI`导出

仪表盘信息示例位于`/usr/share/grafana/conf/provisioning/dashboards/sample.yaml`

```yaml
# # config file version
apiVersion: 1

#providers:
# - name: 'default'
#   orgId: 1
#   folder: ''
#   folderUid: ''
#   type: file
#   options:
#     path: /var/lib/grafana/dashboards
```

自定义`node-exporter-demo`仪表盘，配置文件

```yaml
apiVersion: 1

providers:
  - name: default
    orgId: 1
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: false
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
```

仪表盘描述文件内容过大，见项目仓库[Node-Exporter-Full](volumes/grafana/provisioning/var/dashboards/node-exporter-full.json)

##### 项目文件挂载编排

用户自定义的配置文件和数据文件，需`volume`挂载，下面进行编排规划。

在项目根目录下创建`volumes`文件夹，编排如下

> 学习Linux文件管理规范

```shell
.
├── grafana
│   ├── grafana.ini
│   └── provisioning
│       ├── etc
│       │   ├── dashboards
│       │   │   └── config.yaml
│       │   └── datasources
│       │       └── prometheus-datasource.yaml
│       └── var
│           └── dashboards
│               └── node-exporter-full.json
└── mysql
    └── init.d
        └── grafana.sql
```

**实践思考**：在笔者实践中，没有体会到托管`grafana.db`的价值，默认内嵌`sqlite3`即可。

容器目录挂载，应只关注**与用户相关并产生交互**的文件和目录。

一切安排就绪，可以启动了。

```shell
docker compose up -d 
```

在`Grafana UI`中体验

[数据源：prometheus](http://localhost:9080/connections/datasources)

[仪表盘：Node-Exporter-Full](http://localhost:9080/dashboards)

不再使用时卸载

```shell
docker compose down
```

### 总结

本章节聚焦`Grafana`数据持久化，首先介绍了容器启动的`Grafana`环境变量、配置文件、启动参数，其应用数据默认存于内嵌`sqlite3`，接着阐述如何自行使用`mysql`接管；然后介绍了`Grafana Provisioning`，它能解决仪表盘迁移和版本管理问题，最后通过实践项目体验`Provisioning`的能力。学完本章，对`Grafana`的理解更进一步，但开发范式达不到`CI/CD`的目标。如何使得`Grafana`仪表盘的开发像编写`Java`、`Python`代码一样方便，如何更方便地实现代码复制、开发测试、代码审查、代码发布等，并逐渐向`CI/CD`目标靠近，是下一步工作。

## 参考

1. Node-Exporter，https://github.com/prometheus/node_exporter
2. Grafana，https://grafana.com/
3. Grafana dashboards, Node Exporter Full，https://grafana.com/grafana/dashboards/1860-node-exporter-full/
4. Docker Compose，https://github.com/docker/compose
5. Run Grafana Docker image，https://grafana.com/docs/grafana/next/setup-grafana/installation/docker/#migrate-to-v51-or-later
6. host.docker.internal不生效，https://segmentfault.com/q/1010000042602856
7. connect from a container to a service on the host，https://docs.docker.com/desktop/features/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host
8. 花了三天时间终于搞懂Docker网络了，https://cloud.tencent.com/developer/article/1747307
9. Prometheus配置文件，https://hulining.gitbook.io/prometheus/prometheus/configuration/configuration
10. Prometheus 长期存储主流方案对比，https://kubesphere.io/zh/blogs/prometheus-storage/
11. Provision Grafana，https://grafana.com/docs/grafana/latest/administration/provisioning/
12. Grafana管理历史版本，https://grafana.org.cn/docs/grafana/latest/dashboards/build-dashboards/manage-version-history/
13. Grafana Foundation SDK，https://github.com/grafana/grafana-foundation-sdk
14. Provisioning in Grafana，https://volkovlabs.io/blog/provisioning-grafana-20230509/
