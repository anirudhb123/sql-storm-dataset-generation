
WITH aggregated_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
        AND ca.ca_state = 'CA'
    GROUP BY ws.web_site_sk
),
top_sales AS (
    SELECT 
        web_site_sk,
        total_sales,
        total_orders,
        avg_net_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM aggregated_sales
)
SELECT 
    t.web_site_sk,
    t.total_sales,
    t.total_orders,
    t.avg_net_profit,
    ws.web_name,
    ws.web_manager,
    d.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY d.d_month_seq) AS monthly_orders
FROM top_sales t
JOIN web_site ws ON t.web_site_sk = ws.web_site_sk
JOIN date_dim d ON d.d_year = 2023
WHERE t.sales_rank <= 10
ORDER BY t.total_sales DESC;
