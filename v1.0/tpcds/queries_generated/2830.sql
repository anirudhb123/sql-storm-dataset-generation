
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales IS NOT NULL
)
SELECT 
    hvc.customer_id,
    hvc.total_sales,
    CASE 
        WHEN hvc.sales_rank <= 10 THEN 'Top 10 Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT COUNT(*) FROM store_sales ss 
     WHERE ss.ss_customer_sk = hvc.customer_id) AS store_sales_count,
    (SELECT AVG(cd.cd_purchase_estimate) 
     FROM customer_demographics cd 
     WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = hvc.customer_id)) AS avg_purchase_estimate
FROM 
    HighValueCustomers hvc
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
