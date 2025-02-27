
WITH aggregated_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= 2450000 AND 
        ws.ws_sold_date_sk <= 2451000
    GROUP BY 
        ws.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_ranking AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        RANK() OVER (ORDER BY agg.total_sales DESC) AS sales_rank,
        COALESCE(NULLIF(i.i_brand, ''), 'Unknown Brand') AS brand_name
    FROM 
        item i
    JOIN 
        aggregated_sales agg ON i.i_item_sk = agg.ws_item_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_country,
    ir.i_item_id,
    ir.sales_rank,
    ir.brand_name,
    ir.total_sales
FROM 
    item_ranking ir
JOIN 
    aggregated_sales agg ON ir.i_item_sk = agg.ws_item_sk
JOIN 
    customer_data cd ON cd.c_customer_sk IN (
        SELECT 
            DISTINCT ws.ws_ship_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_qty > 0
    )
WHERE 
    ir.sales_rank <= 10
ORDER BY 
    cd.ca_country, ir.sales_rank;
