
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
),
InactiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    FROM customer c
    WHERE c.c_first_shipto_date_sk IS NULL
)
SELECT 
    COALESCE(r.sales_rank, 'Inactive') AS customer_rank,
    COALESCE(r.c_first_name, ic.c_first_name) AS first_name,
    COALESCE(r.c_last_name, ic.c_last_name) AS last_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.order_count, 0) AS order_count
FROM 
    InactiveCustomers ic
FULL OUTER JOIN SalesRanked r ON ic.c_customer_sk = r.c_customer_sk
WHERE 
    (r.total_sales IS NOT NULL OR ic.c_customer_sk IS NOT NULL)
ORDER BY 
    customer_rank ASC NULLS LAST;
