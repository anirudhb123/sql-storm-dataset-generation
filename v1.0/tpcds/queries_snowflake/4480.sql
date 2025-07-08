
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders
    FROM CustomerSales cs
    WHERE cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    h.total_orders,
    COALESCE(d.d_month_seq, 0) AS sales_month,
    (
        SELECT COUNT(*)
        FROM store_sales ss
        WHERE ss.ss_customer_sk = h.c_customer_sk
        AND ss.ss_sold_date_sk BETWEEN 1000 AND 2000
    ) AS store_sales_count
FROM HighSpenders h
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = h.c_customer_sk)
ORDER BY h.total_sales DESC
LIMIT 10;
