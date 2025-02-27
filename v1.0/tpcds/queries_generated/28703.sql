
WITH address_summary AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_address_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
customer_summary AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
item_summary AS (
    SELECT 
        i_category,
        COUNT(DISTINCT i_item_id) AS total_items,
        SUM(i_current_price) AS total_value
    FROM 
        item
    GROUP BY 
        i_category
),
sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
)
SELECT 
    a.ca_city,
    a.unique_address_count,
    a.avg_gmt_offset,
    c.cd_gender,
    c.total_dependents,
    c.total_purchase_estimate,
    i.i_category,
    i.total_items,
    i.total_value,
    s.web_site_id,
    s.total_sales_price,
    s.total_orders
FROM 
    address_summary a
JOIN 
    customer_summary c ON a.unique_address_count > 100
JOIN 
    item_summary i ON i.total_items < 50
JOIN 
    sales_summary s ON s.total_sales_price > 10000
ORDER BY 
    a.ca_city, c.cd_gender, i.i_category;
