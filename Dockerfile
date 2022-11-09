# Pull base image 
From tomcat:latest

# Maintainer 
MAINTAINER "bharathkothamasu541@gmail.com" 

#copy war file into container
COPY ./webapp.war /usr/local/tomcat/webapps/
