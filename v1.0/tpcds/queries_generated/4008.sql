
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn,
        SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS total_profit
    FROM 
        web_sales
),
filtered_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.total_profit,
        ci.c_current_cdemo_sk,
        ci.c_birth_year,
        ci.c_gender,
        ROW_NUMBER() OVER (PARTITION BY rs.ws_item_sk ORDER BY rs.total_profit DESC) AS item_rank
    FROM 
        ranked_sales rs
    LEFT JOIN 
        customer ci ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        ci.c_birth_year IS NOT NULL
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS total_customers
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
sales_info AS (
    SELECT 
        fs.ws_item_sk,
        fs.ws_order_number,
        fs.total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ci.c_birth_year,
        COUNT(DISTINCT ci.c_customer_id) AS unique_customers
    FROM 
        filtered_sales fs
    JOIN 
        customer_demographics cd ON fs.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        fs.ws_item_sk, fs.ws_order_number, fs.total_profit, cd.cd_gender, cd.cd_marital_status, ci.c_birth_year
)
SELECT 
    si.ws_item_sk,
    si.ws_order_number,
    si.total_profit,
    si.cd_gender,
    si.cd_marital_status,
    si.unique_customers
FROM 
    sales_info si
LEFT JOIN 
    item i ON si.ws_item_sk = i.i_item_sk
WHERE 
    (si.cd_gender = 'F' OR si.cd_gender IS NULL)
    AND si.total_profit > (SELECT AVG(total_profit) FROM sales_info)
ORDER BY 
    si.total_profit DESC
FETCH FIRST 10 ROWS ONLY;
