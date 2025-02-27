
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(NULLIF(tc.total_sales, 0), 1) AS adjusted_sales,
    ROUND(tc.total_sales / NULLIF(tc.order_count, 0), 2) AS average_sales_per_order,
    ARRAY_AGG(CONCAT('Order Count: ', tc.order_count::text)) AS order_details
FROM 
    TopCustomers tc
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name
ORDER BY 
    adjusted_sales DESC
LIMIT 5
UNION
SELECT 
    NULL AS c_customer_sk,
    'Total' AS c_first_name,
    NULL AS c_last_name,
    SUM(total_sales) AS adjusted_sales,
    ROUND(SUM(total_sales) / NULLIF(SUM(order_count), 0), 2) AS average_sales_per_order,
    NULL AS order_details
FROM 
    TopCustomers;
