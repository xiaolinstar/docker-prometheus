# 创建数据库grafana
CREATE DATABASE grafana DEFAULT CHARACTER SET utf8mb4;

# 创建用户
CREATE USER 'admin_grafana'@'%' IDENTIFIED BY 'password_grafana';

# 权限授予（使用更安全的方式管理密码）
GRANT ALL PRIVILEGES ON grafana.* TO 'admin_grafana'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
