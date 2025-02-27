
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer AS c
    LEFT JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
HighestSpendingCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > 5000
)
SELECT 
    hsc.customer_id,
    hsc.total_sales,
    CASE 
        WHEN hsc.total_sales BETWEEN 10000 AND 20000 THEN 'Silver'
        WHEN hsc.total_sales BETWEEN 20001 AND 50000 THEN 'Gold'
        WHEN hsc.total_sales > 50000 THEN 'Platinum'
        ELSE 'Bronze'
    END AS customer_tier,
    COALESCE(cd.cd_gender, 'U') AS gender,
    COALESCE(cd.cd_marital_status, 'U') AS marital_status
FROM 
    HighestSpendingCustomers hsc
LEFT JOIN customer_demographics AS cd ON hsc.customer_id = cd.cd_demo_sk
WHERE hsc.sales_rank <= 100
ORDER BY hsc.total_sales DESC;
