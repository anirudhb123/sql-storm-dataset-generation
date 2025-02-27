
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rank,
        ws_sales_price,
        ws_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
item_aggregate AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ci.total_sales,
        ci.avg_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        item_aggregate ci ON ci.i_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
)
SELECT 
    customer.full_name,
    customer.cd_gender,
    customer.cd_marital_status,
    COALESCE(customer.cd_credit_rating, 'Unknown') AS credit_rating,
    COALESCE(SUM(si.rank), 0) AS sales_rank_count,
    COUNT(DISTINCT customer.c_customer_sk) AS total_customers,
    SUM(customer.total_sales) AS total_sales_amount,
    AVG(customer.avg_profit) AS average_profit
FROM 
    customer_info customer
LEFT JOIN 
    sales_rank si ON customer.c_customer_sk = si.ws_item_sk
GROUP BY 
    customer.full_name, customer.cd_gender, customer.cd_marital_status, customer.cd_credit_rating
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
