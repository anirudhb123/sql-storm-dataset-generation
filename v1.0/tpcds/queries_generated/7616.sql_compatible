
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE dd.d_year = 2023 
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_quantity) AS total_items_purchased,
        SUM(sd.total_revenue) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
        AVG(cd.total_items_purchased) AS avg_items_purchased,
        AVG(cd.total_spent) AS avg_spent
    FROM customer_data cd
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.customer_count,
    da.avg_items_purchased,
    da.avg_spent,
    RANK() OVER (ORDER BY da.avg_spent DESC) AS spending_rank
FROM demographic_analysis da
WHERE da.customer_count > 5
ORDER BY spending_rank;
