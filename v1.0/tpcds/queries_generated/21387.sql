
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
CustomerAge AS (
    SELECT 
        c_customer_sk,
        EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year AS age
    FROM 
        customer
    WHERE 
        c_birth_year IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS web_sales_price,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sales_price > 0
    GROUP BY 
        ws_item_sk
),
SalesComparison AS (
    SELECT 
        cs_item_sk,
        cs_ext_sales_price,
        cs_sales_price,
        cs_net_profit,
        CASE
            WHEN cs_net_profit > 0 THEN 'Profitable'
            WHEN cs_net_profit < 0 THEN 'Loss'
            ELSE 'Break-even'
        END AS profit_status
    FROM 
        catalog_sales
    WHERE 
        cs_ext_sales_price IS NOT NULL
),
CombinedSales AS (
    SELECT 
        r.ss_store_sk,
        c.c_customer_sk,
        s.ws_item_sk,
        s.web_sales_price,
        COALESCE(s.total_net_paid, 0) AS net_paid,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.profit_status
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerAge c ON r.ss_store_sk = c.c_customer_sk
    LEFT JOIN 
        SalesData s ON r.ss_store_sk = s.ws_item_sk
    LEFT JOIN 
        SalesComparison cs ON r.ss_store_sk = cs.cs_item_sk
)
SELECT 
    b.ss_store_sk,
    COUNT(DISTINCT b.c_customer_sk) AS unique_customers,
    AVG(b.age) AS avg_customer_age,
    SUM(b.web_sales_price) AS total_web_sales,
    SUM(b.net_paid) AS total_net_paid,
    MAX(b.profit_status) AS most_common_profit_status
FROM 
    CombinedSales b
WHERE 
    b.net_paid IS NOT NULL
    AND b.profit_status IS NOT NULL
GROUP BY 
    b.ss_store_sk
HAVING 
    AVG(b.age) BETWEEN 18 AND 65
ORDER BY 
    total_web_sales DESC
LIMIT 10;
