
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Income_Ranges AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL AND ib.ib_upper_bound IS NULL THEN 'Unknown'
            WHEN ib.ib_lower_bound IS NULL THEN 'Below ' || ib.ib_upper_bound
            WHEN ib.ib_upper_bound IS NULL THEN 'Above ' || ib.ib_lower_bound
            ELSE CONCAT(ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_range
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
)
SELECT 
    cte.c_first_name,
    cte.c_last_name,
    cte.total_web_sales,
    cte.total_catalog_sales,
    cte.total_store_sales,
    i.income_range,
    ROW_NUMBER() OVER (PARTITION BY i.income_range ORDER BY cte.total_web_sales + cte.total_catalog_sales + cte.total_store_sales DESC) AS rank_within_income,
    CASE 
        WHEN cte.total_web_sales > 1000 THEN 'High Activity'
        WHEN cte.total_web_sales IS NULL THEN 'No Activity'
        ELSE 'Normal Activity'
    END AS activity_level
FROM 
    CTE_Customer_Sales cte
JOIN 
    (SELECT DISTINCT cd.cd_demo_sk, i.income_range 
     FROM Income_Ranges i 
     JOIN customer c ON c.c_current_cdemo_sk = i.cd_demo_sk) i 
ON 
    cte.c_customer_sk = c.c_customer_sk
WHERE 
    (cte.total_web_sales + cte.total_catalog_sales + cte.total_store_sales) > 5000
ORDER BY 
    i.income_range, cte.total_web_sales DESC;
