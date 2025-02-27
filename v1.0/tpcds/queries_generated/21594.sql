
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_sales_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rn
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
CTE_Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE (SELECT ib.ib_income_band_sk FROM household_demographics hd
                  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
                  WHERE hd.hd_demo_sk = cd.cd_demo_sk)
        END AS income_band,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
CTE_Profits AS (
    SELECT 
        c.customer_id,
        (total_web_sales_profit + total_catalog_sales_profit + total_store_sales_profit) AS total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_band
    FROM 
        CTE_Customer_Sales c
    JOIN CTE_Customer_Demographics cd ON c.c_customer_id = cd.customer_id
    WHERE 
        (total_web_sales_profit > 1000 OR total_catalog_sales_profit > 1000 OR total_store_sales_profit > 1000)
        AND cd.cd_marital_status IN ('M', 'S')
),
SELECT 
    p.customer_id,
    p.total_profit,
    p.cd_gender,
    p.cd_marital_status,
    p.income_band
FROM 
    CTE_Profits p
WHERE 
    p.total_profit IS NOT NULL
ORDER BY 
    p.total_profit DESC
LIMIT 10
UNION ALL
SELECT 
    'Total Sales' AS customer_id,
    SUM(total_profit) AS total_profit,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS income_band
FROM CTE_Profits
HAVING COUNT(total_profit) > 0
;
