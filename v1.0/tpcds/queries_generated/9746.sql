
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        MIN(ws_ship_date_sk) AS first_purchase_date,
        MAX(ws_ship_date_sk) AS last_purchase_date
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY ws_bill_customer_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_quantity) AS total_units,
        SUM(sd.total_sales) AS total_revenue,
        COUNT(sd.orders_count) AS total_orders,
        DATEDIFF(year, MIN(sd.first_purchase_date), MAX(sd.last_purchase_date)) AS customer_age_years
    FROM sales_data sd
    JOIN customer c ON c.c_customer_sk = sd.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_units,
        cs.total_revenue,
        RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
    FROM customer_summary cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_units,
    tc.total_revenue,
    tc.revenue_rank
FROM top_customers tc
WHERE tc.revenue_rank <= 100
ORDER BY tc.revenue_rank;
