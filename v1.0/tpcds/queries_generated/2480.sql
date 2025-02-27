
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_country ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        store AS s
    INNER JOIN 
        store_sales AS ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.order_count,
        ss.total_store_sales,
        ss.store_order_count
    FROM 
        CustomerSales cs
    JOIN 
        StoreSales ss ON cs.c_customer_id = (
            SELECT 
                CASE 
                    WHEN cs.sales_rank = 1 AND ss.store_order_count > 0 
                    THEN (SELECT c.c_customer_id FROM customer AS c 
                          WHERE c.c_customer_sk = cs.c_customer_id)
                    ELSE NULL 
                END
            WHERE 
                cs.total_web_sales > 1000
            LIMIT 1
        )
)
SELECT 
    tc.c_customer_id,
    tc.total_web_sales,
    tc.order_count,
    COALESCE(tc.total_store_sales, 0) AS total_store_sales,
    COALESCE(tc.store_order_count, 0) AS store_order_count,
    CASE 
        WHEN tc.total_web_sales > tc.total_store_sales THEN 'More web sales'
        ELSE 'More store sales or equal'
    END AS sales_comparison
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_web_sales DESC;
