
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, ca_country,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_country IS NOT NULL
), sale_summary AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        AVG(cs_sales_price) AS avg_sales_price
    FROM catalog_sales
    GROUP BY cs_item_sk
    HAVING SUM(cs_quantity) > 50
), web_sale_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_web_quantity,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS web_order_count
    FROM web_sales
    GROUP BY ws_item_sk
), combined_sales AS (
    SELECT 
        s.cs_item_sk,
        s.total_quantity,
        s.total_sales,
        s.order_count,
        ws.total_web_quantity,
        ws.total_web_sales,
        ws.web_order_count
    FROM sale_summary s
    LEFT JOIN web_sale_summary ws ON s.cs_item_sk = ws.ws_item_sk
), ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.total_quantity,
        cs.total_sales,
        cs.order_count,
        cs.total_web_quantity,
        cs.total_web_sales,
        cs.web_order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM combined_sales cs
), null_handling AS (
    SELECT 
        r.cs_item_sk,
        COALESCE(r.total_quantity, 0) AS total_quantity,
        COALESCE(r.total_sales, 0) AS total_sales,
        COALESCE(r.order_count, 0) AS order_count,
        COALESCE(r.total_web_quantity, 0) AS total_web_quantity,
        COALESCE(r.total_web_sales, 0) AS total_web_sales,
        COALESCE(r.web_order_count, 0) AS web_order_count
    FROM ranked_sales r
)
SELECT 
    na.ca_city,
    na.ca_state,
    na.ca_zip,
    NA.ca_country,
    nh.sales_rank,
    nh.total_quantity,
    nh.total_sales,
    nh.order_count,
    nh.total_web_quantity,
    nh.total_web_sales,
    nh.web_order_count
FROM address_cte na
FULL OUTER JOIN null_handling nh ON na.rn = 1
WHERE (na.ca_state = 'CA' AND nh.total_sales < 1000) 
   OR (na.ca_country = 'USA' AND nh.order_count > 5)
ORDER BY na.ca_city, nh.total_sales DESC;
