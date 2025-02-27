
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesRank AS (
    SELECT 
        c_customer_id,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    sr.sales_rank,
    d.d_date,
    d.d_day_name
FROM 
    SalesRank sr
JOIN 
    CustomerSales cs ON sr.c_customer_id = cs.c_customer_id
JOIN 
    customer c ON c.c_customer_id = cs.c_customer_id
JOIN 
    date_dim d ON d.d_date_sk = (
        SELECT MIN(ws_sold_date_sk)
        FROM web_sales
        WHERE ws_bill_customer_sk = c.c_customer_sk
          AND ws_net_paid > 0
    )
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.sales_rank;
