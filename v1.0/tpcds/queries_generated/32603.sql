
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_item_sk,
        ss_ticket_number,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_quantity) DESC) AS rn
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk, ss_ticket_number
),
SalesSummary AS (
    SELECT 
        s.s_store_name,
        SUM(ss.total_sales) AS total_sales,
        AVG(ss.total_profit) AS avg_profit,
        MAX(ss.total_quantity) AS max_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_sales
    FROM 
        SalesCTE ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name
),
HighValueStores AS (
    SELECT 
        s_store_name,
        total_sales,
        avg_profit,
        max_quantity,
        unique_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
    WHERE 
        total_sales > 10000
)
SELECT 
    hvs.s_store_name,
    hvs.total_sales,
    hvs.avg_profit,
    hvs.max_quantity,
    hvs.unique_sales,
    CASE 
        WHEN hvs.avg_profit IS NULL THEN 'No Profit' 
        ELSE CAST(hvs.avg_profit AS VARCHAR(10)) 
    END AS avg_profit_display,
    COALESCE(
        (SELECT COUNT(*) 
         FROM customer c 
         JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
         WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
           AND c.c_customer_sk IN (SELECT DISTINCT ss.ss_customer_sk FROM store_sales ss WHERE ss.ss_store_sk = hvs.s_store_name)
        ), 0) AS female_married_customers
FROM 
    HighValueStores hvs
WHERE 
    hvs.sales_rank <= 10
ORDER BY 
    hvs.total_sales DESC;
