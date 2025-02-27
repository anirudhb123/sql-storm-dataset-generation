
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_paid) AS total_sales, 
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        sh.ss_store_sk,
        sh.total_sales * 1.1, 
        h.level + 1
    FROM 
        sales_hierarchy h
    JOIN 
        store_sales sh ON sh.ss_store_sk = h.ss_store_sk
    WHERE 
        h.level < 5
),
customer_with_bonus AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_purchase_estimate, 0) + 
        CASE 
            WHEN cd.cd_credit_rating = 'Good' THEN 100
            WHEN cd.cd_credit_rating = 'Excellent' THEN 200
            ELSE 0 
        END AS adjusted_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
above_average_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cb.adjusted_estimate
    FROM 
        customer_with_bonus cb
    JOIN 
        customer_address ca ON cb.c_customer_sk = ca.ca_address_sk
    WHERE 
        cb.adjusted_estimate > (
            SELECT AVG(adjusted_estimate) 
            FROM customer_with_bonus
        )
),
promotional_items AS (
    SELECT 
        ip.i_item_id, 
        ip.i_item_desc,
        SUM(COALESCE(s.ws_ext_sales_price, 0)) AS total_sales 
    FROM 
        item ip 
    LEFT JOIN 
        web_sales s ON ip.i_item_sk = s.ws_item_sk
    WHERE 
        ip.i_current_price > 50
    GROUP BY 
        ip.i_item_id, 
        ip.i_item_desc
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(si.total_sales) AS total_sales,
    AVG(b.adjusted_estimate) AS average_estimate,
    STRING_AGG(DISTINCT pi.i_item_desc) AS popular_items
FROM 
    above_average_customers b
JOIN 
    customer_address ca ON b.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT si.ss_store_sk, SUM(si.ss_net_paid) AS total_sales 
     FROM store_sales si 
     GROUP BY si.ss_store_sk) store_summary ON b.c_customer_sk = store_summary.ss_store_sk
LEFT JOIN 
    promotional_items pi ON b.c_customer_sk = pi.i_item_id 
GROUP BY 
    ca.ca_city, 
    ca.ca_state
HAVING 
    COUNT(DISTINCT b.c_customer_sk) > 10
ORDER BY 
    total_sales DESC;
