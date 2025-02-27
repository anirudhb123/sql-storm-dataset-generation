
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        SUM(ss_quantity) AS total_items_sold,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk

    UNION ALL

    SELECT 
        s.ss_store_sk,
        ss.total_sales + COUNT(s.ss_ticket_number),
        ss.total_revenue + SUM(s.ss_net_paid),
        ss.total_items_sold + SUM(s.ss_quantity),
        level + 1
    FROM 
        sales_summary ss
    JOIN 
        store_sales s ON ss.ss_store_sk = s.ss_store_sk
    WHERE 
        level < 5
    GROUP BY 
        s.ss_store_sk, ss.total_sales, ss.total_revenue, ss.total_items_sold, level
)

SELECT 
    ca.ca_city,
    SUM(COALESCE(ss.total_revenue, 0)) AS city_revenue,
    AVG(COALESCE(ss.total_sales, 0)) AS avg_sales_per_store,
    MAX(ss.total_items_sold) AS max_items_sold,
    COUNT(ss.ss_store_sk) AS store_count
FROM 
    customer_address ca
LEFT JOIN 
    store s ON ca.ca_address_sk = s.s_store_sk
LEFT JOIN 
    sales_summary ss ON s.s_store_sk = ss.ss_store_sk
WHERE 
    s.s_state = 'CA' 
    AND (ca.ca_city LIKE 'San%' OR COALESCE(ss.total_revenue, 0) > 10000)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(COALESCE(ss.total_revenue, 0)) > 0
ORDER BY 
    city_revenue DESC
LIMIT 10;
