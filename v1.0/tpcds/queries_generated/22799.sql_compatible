
WITH RECURSIVE demographic_summary AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        1 AS level
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
    
    UNION ALL
    
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count + ds.cd_dep_employed_count,
        cd.cd_dep_college_count + ds.cd_dep_college_count,
        ds.level + 1
    FROM customer_demographics cd
    JOIN demographic_summary ds ON cd.cd_demo_sk = ds.cd_demo_sk
    WHERE ds.level < 3
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
high_sales_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        is.total_sales,
        is.order_count,
        RANK() OVER (ORDER BY is.total_sales DESC) AS sales_rank
    FROM item_sales is
    WHERE is.total_sales > (SELECT AVG(total_sales) FROM item_sales)
)
SELECT 
    ca.ca_city,
    SUM(hs.total_sales) AS high_sales_total,
    COUNT(DISTINCT hs.i_item_id) AS unique_items_sold,
    MAX(ds.cd_marital_status) AS most_common_marital_status,
    COUNT(DISTINCT ds.cd_demo_sk) FILTER (WHERE ds.cd_gender = 'F') AS female_customers,
    STRING_AGG(DISTINCT hs.i_item_id) AS item_ids,
    CHOOSER(2, STRING_AGG(DISTINCT ds.cd_credit_rating)) AS rare_credit_ratings
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN high_sales_items hs ON c.c_customer_sk = hs.i_item_sk
LEFT JOIN demographic_summary ds ON c.c_current_cdemo_sk = ds.cd_demo_sk
GROUP BY ca.ca_city
HAVING SUM(hs.total_sales) > 1000
ORDER BY high_sales_total DESC;
