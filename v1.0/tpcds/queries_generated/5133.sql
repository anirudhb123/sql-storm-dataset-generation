
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id, d.d_year
),
top_sales AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_net_paid,
        avg_sales_price,
        RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    ts.web_site_id,
    ts.total_quantity,
    ts.total_net_paid,
    ts.avg_sales_price,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state
FROM top_sales ts
JOIN customer c ON c.c_current_cdemo_sk = (
    SELECT MAX(ca.c_current_cdemo_sk)
    FROM customer_address ca 
    WHERE ca.ca_address_sk = c.c_current_addr_sk
)
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE ts.sales_rank <= 10
ORDER BY ts.total_net_paid DESC;
