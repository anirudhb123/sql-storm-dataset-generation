
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
sales_window AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        AVG(total_sales) OVER () AS avg_sales,
        CASE 
            WHEN total_sales > 1000 THEN 'High'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        customer_sales
),
store_sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS store_total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk IS NOT NULL
    GROUP BY 
        s.s_store_id
    HAVING 
        SUM(ss.ss_net_paid) > 0
)
SELECT 
    cus.c_customer_id,
    cus.c_first_name,
    cus.c_last_name,
    cus.total_sales,
    cus.order_count,
    s.s_store_id,
    s.store_total_sales,
    s.store_order_count,
    CASE 
        WHEN s.store_total_sales IS NULL THEN 'No Sales'
        WHEN s.store_order_count IS NULL THEN 'No Orders'
        ELSE 'Active Store'
    END AS store_activity,
    CASE 
        WHEN cus.sales_rank IS NOT NULL THEN 'Ranked'
        ELSE 'Unranked'
    END AS sales_rank_status
FROM 
    sales_window cus
FULL OUTER JOIN 
    store_sales_summary s ON cus.sales_rank BETWEEN 1 AND 10 /* Fetching top 10 sales customers for store comparisons */
WHERE 
    (cus.total_sales IS NOT NULL OR s.store_total_sales IS NOT NULL)
ORDER BY 
    COALESCE(cus.total_sales, 0) DESC, 
    COALESCE(s.store_total_sales, 0) DESC
LIMIT 100;
