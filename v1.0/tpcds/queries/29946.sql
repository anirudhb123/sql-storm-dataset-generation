
WITH demographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS cities
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender IN ('M', 'F')
    GROUP BY 
        cd.cd_gender
),
items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    HAVING 
        SUM(ws.ws_quantity) > 100
)
SELECT 
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate,
    d.cities,
    i.i_item_id,
    i.total_quantity_sold,
    i.total_sales
FROM 
    demographics d
JOIN 
    items i ON TRUE
ORDER BY 
    d.cd_gender, i.total_sales DESC;
