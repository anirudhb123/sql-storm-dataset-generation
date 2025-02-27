
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank,
        cd.cd_gender,
        ca.ca_city,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451537 AND 2451830
    GROUP BY ws.web_site_sk, ws.ws_net_profit, cd.cd_gender, ca.ca_city
),
sales_summary AS (
    SELECT 
        r.web_site_sk,
        SUM(r.ws_net_profit) AS total_net_profit,
        AVG(r.ws_net_profit) AS avg_net_profit,
        MAX(r.ws_net_profit) AS max_net_profit,
        COUNT(DISTINCT r.sales_rank) AS unique_sales_rank_count
    FROM ranked_sales r
    WHERE r.sales_rank = 1
    GROUP BY r.web_site_sk
)
SELECT 
    s.web_site_sk,
    s.total_net_profit,
    s.avg_net_profit,
    s.max_net_profit,
    COALESCE(ca.ca_country, 'Unknown') AS country,
    CASE 
        WHEN s.avg_net_profit > 1000 THEN 'High Performer'
        WHEN s.avg_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM sales_summary s
LEFT JOIN customer_address ca ON s.web_site_sk = ca.ca_address_sk
ORDER BY s.total_net_profit DESC, s.avg_net_profit ASC;
