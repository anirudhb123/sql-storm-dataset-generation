
WITH sales_summary AS (
    SELECT 
        w.warehouse_name,
        d.d_year,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_sales_price) AS total_sales_amount,
        AVG(ws_net_profit) AS average_net_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2021 AND 2023
    GROUP BY w.warehouse_name, d.d_year
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ss.warehouse_name,
    ss.d_year,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.average_net_profit,
    cs.cd_gender,
    cs.total_spent,
    cs.unique_customers
FROM sales_summary ss
JOIN customer_summary cs ON ss.total_sales_amount > cs.total_spent
ORDER BY ss.d_year, ss.total_sales_amount DESC;
