
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - INTERVAL '30 days'
), 
CustomerCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
ItemCTE AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_net_profit) AS avg_profit_per_item
    FROM 
        item AS i
    JOIN 
        web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
    c.cd_gender,
    c.total_profit,
    i.i_product_name,
    i.total_sold,
    (i.avg_profit_per_item - COALESCE(NULLIF(i.total_sold, 0), 1)) AS adjusted_profit,
    CASE 
        WHEN c.cd_marital_status = 'M' THEN 'Married' 
        ELSE 'Single' 
    END AS marital_status,
    ROW_NUMBER() OVER (PARTITION BY c.cd_gender ORDER BY c.total_profit DESC) AS gender_rank
FROM 
    CustomerCTE c
JOIN 
    ItemCTE i ON c.orders_count > 10
ORDER BY 
    adjusted_profit DESC
LIMIT 100
OFFSET 0;
