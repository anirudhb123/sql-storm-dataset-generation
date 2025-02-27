
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
SalesDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_web_sales) AS total_web_sales_by_demo,
        SUM(cs.total_store_sales) AS total_store_sales_by_demo
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
SalesCompared AS (
    SELECT 
        sd.cd_gender,
        sd.cd_marital_status,
        sd.total_web_sales_by_demo,
        sd.total_store_sales_by_demo,
        (sd.total_web_sales_by_demo - sd.total_store_sales_by_demo) AS sales_difference
    FROM SalesDemographics sd
    WHERE sd.total_web_sales_by_demo > sd.total_store_sales_by_demo
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(s.sales_difference) AS avg_sales_difference,
    COUNT(*) AS demo_count
FROM SalesCompared s
JOIN customer_demographics cd ON s.cd_gender = cd.cd_gender AND s.cd_marital_status = cd.cd_marital_status
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY avg_sales_difference DESC
LIMIT 10;
