
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
        ss.total_sales + s.total_sales,
        ss.total_revenue + s.total_revenue,
        ss.total_items_sold + s.total_items_sold,
        level + 1
    FROM 
        sales_summary ss
    JOIN 
        store_sales s ON ss.ss_store_sk = s.ss_store_sk
    WHERE 
        level < 5
)

SELECT 
    s.ca_city,
    SUM(COALESCE(ss.total_revenue, 0)) AS city_revenue,
    AVG(COALESCE(ss.total_sales, 0)) AS avg_sales_per_store,
    MAX(ss.total_items_sold) AS max_items_sold,
    CASE 
        WHEN COUNT(ss.ss_store_sk) > 0 THEN COUNT(ss.ss_store_sk)
        ELSE NULL 
    END AS store_count
FROM 
    customer_address ca
LEFT JOIN 
    store s ON ca.ca_address_sk = s.s_store_sk
LEFT JOIN 
    sales_summary ss ON s.s_store_sk = ss.ss_store_sk
WHERE 
    s.s_state = 'CA' 
    AND (ca.ca_city LIKE 'San%' OR ss.total_revenue > 10000)
GROUP BY 
    ca.ca_city
HAVING 
    city_revenue > 0
ORDER BY 
    city_revenue DESC
LIMIT 10;

-- Reset results for benchmarking
SELECT
    ROW_NUMBER() OVER (ORDER BY ca.ca_city) AS row_num,
    ca.ca_city,
    SUM(COALESCE(ss.total_revenue, 0)) AS city_revenue
FROM 
    customer_address ca
LEFT JOIN 
    store s ON ca.ca_address_sk = s.s_store_sk
LEFT JOIN 
    sales_summary ss ON s.s_store_sk = ss.ss_store_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    city_revenue DESC;

-- Aggregate performance comparison
SELECT 
    'City Revenue' AS metric_type,
    SUM(city_revenue) AS total
FROM (
    SELECT 
        ca.ca_city,
        SUM(COALESCE(ss.total_revenue, 0)) AS city_revenue
    FROM 
        customer_address ca
    LEFT JOIN 
        store s ON ca.ca_address_sk = s.s_store_sk
    LEFT JOIN 
        sales_summary ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        ca.ca_city
) AS city_data
WHERE 
    city_revenue > 5000
UNION ALL
SELECT 
    'Average Sale per Store' AS metric_type,
    AVG(avg_sales_per_store) AS total
FROM (
    SELECT 
        s.s_store_sk,
        AVG(ss.total_sales) AS avg_sales_per_store
    FROM 
        store s
    LEFT JOIN 
        sales_summary ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
) AS store_data;
