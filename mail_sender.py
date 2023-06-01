import smtplib, ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from config import *
import sys

ghrepo = str(sys.argv[1])
recipient_email = str(sys.argv[2])

html_file = '/tmp/.crawlghpr/sendmail.html'
email_subject = "Digest | Pull Request Stats for GH repo "+ghrepo

message = MIMEMultipart("alternative")
message["Subject"] = email_subject
message["From"] = sender_email
message["To"] = recipient_email

with open(html_file, 'r') as file:
    html = file.read().replace('\n', '')

mail_content = MIMEText(html, "html")

# Add HTML/plain-text parts to MIMEMultipart message
message.attach(mail_content)

print("[*] Sending mail with following details:\n\tFrom: %s\tTo: %s\n\tSubject: %s" % (sender_email, recipient_email, email_subject))

# Create secure connection with server and send email
context = ssl.create_default_context()
with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
    server.login(sender_email, sender_password)
    server.sendmail(
        sender_email, recipient_email, message.as_string()
    )

print("[+] Mail Sent")
