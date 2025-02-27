
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_income
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2021 AND 2023
    GROUP BY ws.ws_item_sk
),
promotional_sales AS (
    SELECT 
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY p.p_promo_name
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.total_returns,
    ci.total_return_amt,
    is.total_quantity_sold,
    is.total_sales_income,
    ps.promo_name,
    ps.total_net_paid
FROM customer_info ci
LEFT JOIN item_sales is ON ci.c_customer_id = is.ws_item_sk
LEFT JOIN promotional_sales ps ON is.total_quantity_sold > 100
ORDER BY ci.total_return_amt DESC, ps.total_net_paid DESC
LIMIT 100;
