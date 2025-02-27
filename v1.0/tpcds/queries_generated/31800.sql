
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk, 
        SUM(ws_net_profit) AS total_profit 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        ws_bill_customer_sk

    UNION ALL

    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt) * -1 
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        sr_customer_sk
),
ranked_sales AS (
    SELECT 
        customer_sk, 
        total_profit, 
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank 
    FROM 
        sales_hierarchy
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate 
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
)
SELECT 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    r.total_profit, 
    r.profit_rank 
FROM 
    customer_info ci 
LEFT JOIN 
    ranked_sales r ON ci.c_customer_id = r.customer_sk 
WHERE 
    r.profit_rank <= 10 OR r.profit_rank IS NULL
ORDER BY 
    r.profit_rank ASC NULLS LAST;

