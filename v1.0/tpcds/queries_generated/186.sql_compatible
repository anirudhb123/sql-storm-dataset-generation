
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.web_order_count,
        cs.store_order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_web_sales > 1000
),
Result AS (
    SELECT 
        hvc.c_customer_id,
        hvc.total_web_sales,
        hvc.web_order_count,
        hvc.store_order_count,
        COALESCE(sd.sf_sales, 0) AS sales_from_store
    FROM 
        HighValueCustomers hvc
    LEFT JOIN (
        SELECT 
            cs_bill_customer_sk,
            SUM(cs_ext_sales_price) AS sf_sales
        FROM 
            catalog_sales
        GROUP BY 
            cs_bill_customer_sk
    ) sd ON hvc.c_customer_id = sd.cs_bill_customer_sk
)
SELECT 
    r.c_customer_id, 
    r.total_web_sales, 
    r.web_order_count, 
    r.store_order_count, 
    r.sales_from_store,
    CASE 
        WHEN r.total_web_sales > 1500 THEN 'High Value'
        WHEN r.total_web_sales BETWEEN 1000 AND 1500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    Result r
WHERE 
    r.store_order_count > 0 
ORDER BY 
    r.total_web_sales DESC;
