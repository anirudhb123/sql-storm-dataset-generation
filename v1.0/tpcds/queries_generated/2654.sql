
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    INNER JOIN 
        item ON ws_item_sk = i_item_sk
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
top_sellers AS (
    SELECT 
        i_item_id, 
        total_quantity, 
        total_sales 
    FROM 
        ranked_sales
    WHERE 
        rank <= 10
),
customer_regional_info AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_state
)
SELECT 
    t.ca_state,
    COALESCE(cr.customer_count, 0) AS customer_count,
    COALESCE(cr.highest_credit_rating, 'Unknown') AS highest_credit_rating,
    SUM(ts.total_quantity) AS total_quantity_sold,
    SUM(ts.total_sales) AS total_sales_value
FROM 
    customer_regional_info cr 
FULL OUTER JOIN 
    top_sellers ts ON cr.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = ts.ws_item_sk) 
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
JOIN 
    warehouse w ON i.i_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    t.ca_state
HAVING 
    SUM(ts.total_quantity) > 0 OR COUNT(DISTINCT cr.customer_count) > 0
ORDER BY 
    total_sales_value DESC;
