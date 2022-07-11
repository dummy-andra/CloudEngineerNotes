> #  “Cannot connect to amqp…” error

<br /><br />

> `Cannot connect to amqp://guest@127.0.0.1:5672//: [Errno 111] Connection refused.`
 
Looks like command connected to the default broker not the specified one or something it’s blocking the connection.

![](pics\error.png)

<br /><br />


### Action:
 
If you do sudo netstat -tulpn | grep LISTEN can you see the port 5672 oppened?

![](pics\netstat.png)



If not that means that RabbitMQ it’s not installed
 
Bellow you can see the steps I took to install it on the vm (the numerotation is hron linux history command, use the commands without the numbers in front):
```
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get update -y
sudo apt-get install -y erlang erlang-nox
echo 'deb http://www.rabbitmq.com/debian/ testing main' | sudo tee /etc/apt/sources.list.d/rabbitmq.list
wget -O- https://www.rabbitmq.com/rabbitmq-release-signing-key.asc | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install -y rabbitmq-server
sudo systemctl start rabbitmq-server
sudo systemctl status rabbitmq-server
sudo systemctl enable rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl add_user admin password 
cd celery/examples/django/
celery -A proj worker -l INFO
sudo netstat -tulpn | grep LISTEN
```
 
 
 
After you install the RabbitMQ on the vm test again the connection.


<br /><br />


### Additional information:
<br /><br />


 
From the documentation https://docs.celeryproject.org/en/latest/django/first-steps-with-django.html#using-celery-with-django
 
I found out that  it was added Django settings module as a configuration source for Celery:  `app.config_from_object('django.conf:settings', namespace='CELERY') `

In this case it is needed to prefix your settings with CELERY, so in case you use `BROKER_URL`  change it to `CELERY_BROKER_URL = 'redis://127.0.0.1:6379'`
 
 
Another question is where you defined the celery?
 
Let’s say if you defined celery inside of  myapp/server.py,  you need to run: celery -A  myapp.server.celery worker   instead of celery -A celery worker
(web.server indicates that  celery object is in a file server.py inside a directory myapp)
 
 


#### You can also try using redis instead of rabbitmq:
As you can see from my example above I deployed Bitnami Weblate version (4.3.2), after I installed redis I checked the connection to it 

``` 
Install Redis
$ sudo apt install redis-server
$ redis-server --version
Redis server version 2.4.14 (00000000:0)
 
Check if Redis is up and accepting connections:
$ redis-cli ping
PONG
```
 
For this test I used the Example Django project using Celery from the Celery github:https://github.com/celery   (link to the full project https://github.com/celery/celery/tree/master/examples/django)
 
I did the fallowing modification in celery.py


![](pics\celery.png)


#### Output
![](pics\output.png)


<br /><br />

<br /><br />

> #  Webtemplate 4.3 and 4.4 mailing issues.
<br /><br />




> One of the cause can be that Backend email was set to dummy. 
`EMAIL_BACKEND = django.core.mail.backends.dummy.EmailBackend`


> Fix it be Changing it to smtp
`EMAIL_BACKEND = django.core.mail.backends.smtp.EmailBackend`
 

https://docs.djangoproject.com/en/dev/topics/email/#smtp-backend
https://docs.djangoproject.com/en/dev/topics/email/#dummy-backend
