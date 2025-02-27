
WITH RECURSIVE customer_chain AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cc.level + 1
    FROM 
        customer c
    JOIN 
        customer_chain cc ON cc.c_customer_sk = c.c_current_cdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > cc.cd_purchase_estimate
),
early_returns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        COUNT(*) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk < (
            SELECT MAX(sr1.returned_date_sk) 
            FROM store_returns sr1
            WHERE sr1.returned_date_sk IS NOT NULL
        )
    GROUP BY 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.item_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    COALESCE(ear.total_returns, 0) AS total_returns,
    COALESCE(sales.total_sales, 0) AS total_sales,
    COALESCE(sales.avg_profit, 0) AS avg_profit
FROM 
    customer_chain c
JOIN 
    customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    early_returns ear ON ear.item_sk = c.c_customer_sk
LEFT JOIN 
    sales_summary sales ON sales.ws_item_sk = c.c_customer_sk
WHERE 
    c.c_birth_year IS NOT NULL 
    AND (c.c_birth_month, c.c_birth_day) = (SELECT MIN(c2.c_birth_month), MIN(c2.c_birth_day) FROM customer c2 WHERE c2.c_birth_year = c.c_birth_year)
ORDER BY 
    c.c_last_name, c.c_first_name, c.c_birth_year DESC
LIMIT 100
OFFSET 25;
