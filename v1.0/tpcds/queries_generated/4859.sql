
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_sales_price - ws.ws_ext_discount_amt AS ws_net_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT MAX(ws2.ws_sold_date_sk) 
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = ws.ws_item_sk
        )
),
aggregated_sales AS (
    SELECT 
        item.i_item_id,
        SUM(rs.ws_net_sales) AS total_net_sales,
        COUNT(rs.ws_order_number) AS total_orders
    FROM 
        item
    LEFT JOIN 
        ranked_sales rs ON item.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.rank = 1
    GROUP BY 
        item.i_item_id
),
customer_stats AS (
    SELECT 
        cd.cd_gender,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    as.total_net_sales,
    as.total_orders,
    cs.cd_gender,
    cs.avg_vehicle_count,
    cs.num_customers
FROM 
    aggregated_sales as
CROSS JOIN 
    customer_stats cs
WHERE 
    as.total_net_sales > (
        SELECT AVG(total_net_sales) FROM aggregated_sales
    )
ORDER BY 
    as.total_net_sales DESC
LIMIT 10;
