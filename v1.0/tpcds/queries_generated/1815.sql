
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name
    FROM CustomerSales cs
    WHERE cs.sales_rank <= 10
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(CAST(NULLIF(CAST(SUM(ws.ws_ext_sales_price) AS DECIMAL(10, 2)), 0) AS VARCHAR), 'No Sales') , 'No Sales') AS total_sales
FROM customer c
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE c.c_customer_sk IN (SELECT h.c_customer_sk FROM HighValueCustomers h)
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
UNION ALL
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    'Inactive Customer' AS total_sales
FROM customer c
WHERE c.c_customer_sk NOT IN (SELECT cs.c_customer_sk FROM CustomerSales cs)
ORDER BY total_sales DESC;
