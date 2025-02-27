
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_profit,
    ar.total_annual_return,
    COALESCE(CASE 
                WHEN ci.total_profit > 1000 THEN 'High'
                WHEN ci.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
                ELSE 'Low' 
              END, 'NA') AS profit_category
FROM Customer_Info ci
JOIN (
    SELECT 
        COUNT(DISTINCT ws_item_sk) AS item_count,
        SUM(ws_net_paid) AS total_annual_return
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MIN(d_date_sk)
        FROM date_dim
        WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
    )
    AND ws_sold_date_sk < (
        SELECT MIN(d_date_sk)
        FROM date_dim
        WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE)
    )
) ar ON ci.c_customer_sk IS NOT NULL
ORDER BY ci.total_profit DESC
LIMIT 100;
