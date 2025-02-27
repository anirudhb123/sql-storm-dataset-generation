
WITH RECURSIVE sales_data AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.quantity) AS total_quantity,
        SUM(ss.net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.sold_date_sk DESC) AS rn
    FROM 
        store_sales ss
    GROUP BY 
        ss.sold_date_sk, ss.item_sk
), 
item_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_profit, 0) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        sales_data s ON i.i_item_sk = s.item_sk AND s.rn = 1
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
filtered_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        customer_info ci
    WHERE 
        ci.gender_rank <= 5
)

SELECT 
    is.i_item_desc,
    fc.c_customer_id,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_purchase_estimate,
    SUM(is.total_profit) AS total_profit_by_customer
FROM 
    item_summary is
JOIN 
    store_sales ss ON is.i_item_sk = ss.ss_item_sk
JOIN 
    filtered_customers fc ON ss.ss_customer_sk = fc.c_customer_id
WHERE 
    is.total_quantity > 0
GROUP BY 
    is.i_item_desc, fc.c_customer_id, fc.cd_gender, fc.cd_marital_status, fc.cd_purchase_estimate
HAVING 
    SUM(is.total_profit) > 1000
ORDER BY 
    total_profit_by_customer DESC
LIMIT 10;
