
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk 
), 
top_items AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales_price
    FROM 
        sales_summary s
    WHERE 
        s.rank <= 10
), 
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        t.total_quantity,
        t.total_sales_price
    FROM 
        top_items t
    JOIN 
        item i ON t.ws_item_sk = i.i_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
sales_data AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        item_details id ON ws.ws_item_sk = id.ws_item_sk
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
)
SELECT 
    sd.*, 
    CASE 
        WHEN sd.cd_marital_status = 'M' THEN 'Married'
        WHEN sd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status_desc,
    CASE 
        WHEN sd.cd_gender IS NULL THEN 'Unknown'
        ELSE sd.cd_gender
    END AS gender_desc
FROM 
    sales_data sd
WHERE 
    sd.total_profit > (SELECT AVG(total_profit) FROM sales_data)
ORDER BY 
    total_profit DESC
LIMIT 20;
