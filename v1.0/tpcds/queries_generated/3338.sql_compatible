
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
StoreSales AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS total_store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
CombinedSales AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        COALESCE(hvc.total_sales, 0) AS online_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        COALESCE(hvc.total_sales, 0) + COALESCE(ss.total_store_sales, 0) AS total_combined_sales
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        StoreSales ss ON hvc.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.online_sales,
    c.store_sales,
    c.total_combined_sales,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_count
FROM 
    CombinedSales c
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_ship_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    c.online_sales,
    c.store_sales,
    c.total_combined_sales,
    d.d_year
HAVING 
    c.total_combined_sales > 1000
ORDER BY 
    c.total_combined_sales DESC
LIMIT 10;
