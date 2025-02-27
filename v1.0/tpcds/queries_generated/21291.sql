
WITH RECURSIVE address_cte AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(*) OVER (PARTITION BY ca_state) AS state_count
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
) 
, demographic_info AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_deps,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
) 
, item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
) 
SELECT 
    a.ca_city, 
    d.cd_gender, 
    i.i_product_name,
    CASE 
        WHEN a.state_count > 50 THEN 'High Density'
        WHEN a.state_count BETWEEN 20 AND 50 THEN 'Medium Density'
        ELSE 'Low Density' 
    END AS density_category,
    COALESCE(i.total_sold, 0) AS total_sold,
    d.total_deps,
    d.avg_purchase_estimate,
    ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY i.total_sold DESC) AS sales_rank,
    RANK() OVER (PARTITION BY a.ca_city ORDER BY d.avg_purchase_estimate DESC) AS demographic_rank
FROM 
    address_cte a
LEFT JOIN demographic_info d ON a.ca_state = d.cd_gender
LEFT JOIN item_sales i ON i.total_sold IS NOT NULL 
WHERE 
    a.ca_city NOT IN (SELECT ca_city FROM customer_address WHERE ca_state = 'XX')
    OR a.ca_state = (SELECT NULLIF(MIN(ca_state), 'NY') FROM customer_address)
ORDER BY 
    a.ca_city ASC, 
    d.cd_gender DESC,
    i.total_sold DESC
LIMIT 100 OFFSET 10;
