一、安装tomcat
	tomcat的安装分为安装JDK和安装tomcat两个步骤。JDK是整个java的核心，它包括了java运行环境、java工具和java基础的类库。所以想要运行java程序必须要有JDK的支持，而安装tomcat的前提也是安装好JDK。
1、安装JDK
	#cd /usr/local/src
	#tar zxvf jdk-8u101-linux-x64.tar.gz
	#mv jdk1.8.0_101 /usr/local/jdk1.8
	然后设置环境变量，
	#vim /etc/profile 	//在末尾输入以下内容：
JAVA_HOME=/usr/local/jdk1.8/
JAVA_BIN=/usr/local/jdk1.8/bin
JRE_HOME=/usr/local/jdk1.8/jre
PATH=$PATH:/usr/local/jdk1.8/bin:/usr/local/jdk1.8/jre/bin
CLASSPATH=/usr/local/jdk1.8/jre/lib:/usr/local/jdk1.8/lib:/usr/local/jdk1.8/jre/lib/charsets.jar
	#source /etc/profile
	检查设置是否正确
	#java -version
	如果显示如下内容，则说明配置正确：
	java version "1.8.0_101"
	java(TM) SE Runtime Environment (build 1.8.0_101-b13)
	java HotSpot(TM) 64-Bit Server VM (build 25.101-b13,mixed mode)
	在这一步也许显示的不一样，这可能是因为系统调用了rpm的openjdk，可安装如下方法检测:
	#which java
	如果结果为/usr/bin/java则说明这是rpm的JDK，而且执行java-version时会有openjdk字样。其实我们也可以直接使用openjdk。临时处理：
	#mv /usr/bin/java /usr/bin/java_bak
	#source /etc/profile
	再次执行java -version，显示结果就正常了。
2、安装Tomcat
	#cd /usr/local/src/
	#wget https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.5.31/src/apache-tomcat-8.5.31-src.tar.gz
	#tar zxvf apache-tomcat-8.5.13.tar.gz
	#mv apache-tomcat-8.5.13 /usr/local/tomcat
	因为是二进制包，所以免去了编译的过程，启动tomcat
	#/usr/local/tomcat/bin/startup.sh
	查看是否启动成功，命令如下：
	#ps aux|grep tomcat
	#netstat -lntp|grep java
	//正常会有三个端口8009、8005和8080，其中8080为提供web服务的端口，8005为管理断藕，8009端口为第三方服务调用的端口，比如httpd和tomcat结合时会用到
	若想开机启动，需要把启动命令放到/etc/rc.d/rc.local文件里。如下：
	#echo "/usr/local/tomcat/bin/startup.sh" >> /etc/rc.d/rc.local/jdk1
	#chmod a+x /etc/rc.d/rc.local/jdk1	//默认该文件没有x权限，所有需要加
	然后在浏览器中输入http://localhost:8080/，你会看到tomcat的默认页面
二、配置tomcat
1、配置tomcat服务的访问端口
	tomcat默认启动的端口是8080，可以在server.xml文件修改。
	#vim /usr/local/tomcat/conf/server.xml
	找到Connector port="8080" protocol="HTTP/1.1",修改为<Connector port="80" protocol="HTTP/1.1"。保存文件后重启tomcat，命令如下：
	#/usr/local/tomcat/bin/shutdown.sh
	#/usr/local/tomcat/bin/startup.sh
	tomcat的关闭和启动有点特殊，需要使用它自带的脚本实现。在生产环境，tomcat会使用8080端口，而80端口是留给nginx的。也就是说想访问tomcat，需要使用nginx代理。
2、tomcat的虚拟主机
	打开配置文件/usr/local/tomcat/conf/server.xml查看一下它的结构，其中<!--和-->之间的内容为注释掉的，可以不用关注。
	其中<Host>和</Host>之间的配置为虚拟主机配置部分，name定义域名，appBase定义应用的目录。java的应用通常是一个jar的压缩包，将jar的压缩包放到appBase目录下面即可。刚刚访问的tomcat默认也其实就是在appBase目录下面，不过是在它子目录ROOT里：
	#ls /usr/local/tomcat/webapps/ROOT/
	其中index.jsp就是tomcat的默认页面。
	在appBase(/usr/local/tomcat/webapps)目录下面有很多子目录，每一个子目录都可以被访问，你可以把自定义的应用放到webapps目录里（假设应用名字为aming，aming为一个目录），然后可以通过http://ip/aming/来访问这个应用。如果直接访问IP，后面不加二级目录，则默认会访问ROOT目录下面的文件，加上二级目录会访问二级目录下面的文件。
<Host name="www.123.cn" appBase="/data/tomcatweb/"
    unpackWARs="false" autoDeploy="true"
    xmlValidation="false" xmlNamespaceAware="false">
    <Context path="" docBase="/data/tomcatweb/" debug="0" reloadable="true" crossContext="true"/>
</Host>
	其中多了一个docBase，这个参数用来定义网站的文件存放路径，如果不定义，默认在appBase/ROOT下面的。定义了docBase就以该目录为主了，其中appBase和docBase可以一样。创建目录和测试文件并测试，过程如下：
	#mkdir /data/tomcatweb
	#echo "Tomcat test page." >/data/tomcatweb/1.html
	修改完配置文件后，需要重启tomcat服务：
	#/usr/local/tomcat/bin/shutdown.sh
	#/usr/local/tomcat/bin/startup.sh
	然后用curl访问刚才创建的1.html：
	#curl -x127.0.0.1:8080 www.123.cn/1.html
	tomcat test page.
3、测试tomcat解析JSP
	以上的操作，仅仅是把tomcat作为一个普通的web server，其实tomcat主要用来解析JSP页面。
	#vim /data/tomcatweb/111.jsp
	<html><body><center>
		now time is: <%=new java.util.Date()%>
	</center></body></html>
	保存文件后石永红curl测试，
	#curl -x127.0.0.1:8080 www.123.cn/111.jsp
	查看运行结果是否正确，
	<html><body><center>
		now time is: mon apr 03 12 12:59:13 CST 2017
	</center></body></html>
4、tomcat日志
	tomcat的日志目录为/usr/tomcat/logs，主要有四大类日志：
	#cd /usr/local/tomcat/logs
	#ls
	其中catalina开头的日志为tomcat的综合日志，它记录tomcat服务相关信息，也会记录错误日志。其中，catalina.2017-04-03.log和catalina.out内容相同，前者会每天生成一个新日志。host-manager和manager为管理相关的日志，其中host-manager为虚拟主机的管理日志。localhost和localhost_access为虚拟主机相关日志，其中带access字样的日志为访问日志，不带access字样的为默认虚拟主机的错误日志。访问日志默认不会生成，需要在server.xml中配置一下。具体方法是在对应虚拟主机的<Host></Host>里面加入下面的配置（假如域名为123.cn）：
<Value className="org.apache.catalina.valves.AccessLogValve" directory="logs"
	prefix="123.cn_access_log" suffix=".txt"
	pattern="%h %l %u %t &quot;%r&quot; %s %b" />
	prefix定义访问日志的前缀，suffix定义日志的后缀，pattern定义日志格式。新增加的虚拟主机默认并不会生成类似默认虚拟主机的那个"localhost.日期.log"日志，错误日志会统一记录到catalina.out中。关于tomcat日志，最需要关注catalina.out。
5、tomcat连接mysql
	tomcat连接mysql是通过自带的JDBC驱动实现的。
	首先，配置mysql，创建实验用的库、表以及用户：
	#mysql -uroot -p'123456'
	mysql>create database java_test;
	mysql>use java_test
	mysql>grant all on java_test.* to 'java'@'127.0.0.1' identified by 'aminglinux';
	mysql>create table aminglinux (`id` int(4), `name` char(40));
	mysql>insert into aminglinux values (1, 'abc');
	mysql>insert into aminglinux values (2, 'aaa');
	mysql>insert into aminglinux values (3, 'ccc');
	创建完表以及用户后，退出mysql，并验证用户是否可用：
	#mysql -ujava -paminglinux -h127.0.0.1
	正常进入mysql，说明创建的java用户没有问题。接着去配置tomcat相关的配置文件：
	#vim /usr/local/tomcat/conf/context.xml //在</Context>上面增加以下内容
    <Resource name="jdbc/mytest"
        auth="Container"
        type="javax.sql.DataSource"
        maxActive="100" maxIdle="30" maxWait="10000"
        username="java" password="aminglinux"
        driverClassName="com.mysql.jdbc.Driver"
        url="jdbc:mysql://127.0.0.1:3306/java_test">
    </Resource>
	其中，name定义为jdbc/mytest,这里的mytest可以自定义。username为mysql的用户，password为密码，usrl定义mysql的ip、端口以及库名。保存该文件后，还需要更改另外一个配置文件：
	#vim /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml
	<resource-ref>
	   <description>DB Connection</description>
	   <res-ref-name>jdbc/mytest</res-ref-name>
	   <res-type>javax.sql.DataSource</res-type>
	   <res-auth>Container</res-auth>
    </resource-ref>
	其实每一个应用（上文提到的webapps/ROOT、webapps/aming等）目录下都应该有一个WEB-INF目录，它里面会有对应的配置文件，比如web.xml就是用来定义JDBC相关资源的，其中的res-ref-name和前面定义的Resource name保持一致。既然选择了webapps/ROOT作为实验应用对象，就需要在ROOT目录下面创建测试JSP文件(用浏览器访问的文件）：
	#vim /usr/local/tomcat/webapps/ROOT/t.jsp
	<%@page import="java.sql.*"%>
	<%@page import="javax.sql.DataSource"%>
	<%@page import="javax.naming.*"%>

	<%
	Context ctx = new InitialContext();
	DataSource ds = (DataSource) ctx
	.lookup("java:comp/env/jdbc/mytest");
	Connection conn = ds.getConnection();
	Statement state = conn.createStatement();
	String sql = "select * from aminglinux";
	ResultSet rs = state.executeQuery(sql);

	while (rs.next()) {
	out.println(rs.getString("id") +"<tr>");
	out.println(rs.getString("name") +"<tr><br>");
	}

	rs.close();
	state.close();
	conn.close();
	%>
	这个脚本会去连接MYSQL，并查询一个库、表的数据。保存后，重启tomcat：
	#/usr/local/tomcat/bin/shutdown
	#/usr/local/tomcat/bin/startup
	
	