
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    STRING_AGG(DISTINCT cp.cp_catalog_page_id) AS catalog_ids,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = tc.c_customer_sk 
     AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS store_order_count
FROM 
    TopCustomers tc
LEFT JOIN 
    catalog_page cp ON cp.cp_catalog_page_sk IN (SELECT DISTINCT cat.cs_catalog_page_sk 
                                                  FROM catalog_sales cat 
                                                  WHERE cat.cs_bill_customer_sk = tc.c_customer_sk)
WHERE 
    tc.sales_rank <= 10
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name
ORDER BY 
    total_sales DESC;
