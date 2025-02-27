
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_sales) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY 
        c.c_customer_id
), StoreSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_sales) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS ticket_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY 
        c.c_customer_id
), CombinedSales AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        (cs.order_count + ss.ticket_count) AS total_transactions
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_id = ss.c_customer_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.web_sales,
    cs.store_sales,
    cs.total_sales,
    cs.total_transactions
FROM 
    CombinedSales cs
JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
WHERE 
    total_sales > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
