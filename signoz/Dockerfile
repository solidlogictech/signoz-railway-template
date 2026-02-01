FROM signoz/signoz:v0.110.0

COPY signoz/signoz/prometheus.yml /root/config/prometheus.yml
COPY signoz/dashboards /root/config/dashboards

CMD ["./signoz", "server"]
