
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        cd.cd_gender,
        cd.cd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_income_band_sk, cd.cd_gender ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        rs.rank_sales,
        rs.ws_sales_price
    FROM 
        ranked_sales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.rank_sales <= 10
),
category_avg AS (
    SELECT 
        item.i_category,
        AVG(ts.ws_sales_price) AS avg_price
    FROM 
        top_sales ts
    JOIN 
        item ON ts.i_item_id = item.i_item_id
    GROUP BY 
        item.i_category
)
SELECT 
    ca.ca_city,
    avg_ca.avg_price,
    COUNT(DISTINCT ts.ws_order_number) AS total_orders
FROM 
    customer_address ca
JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    top_sales ts ON ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_customer_sk = c.c_customer_sk)
JOIN 
    category_avg avg_ca ON item.i_category_id = avg_ca.i_category_id
GROUP BY 1, 2
ORDER BY total_orders DESC, avg_price DESC
LIMIT 20;
