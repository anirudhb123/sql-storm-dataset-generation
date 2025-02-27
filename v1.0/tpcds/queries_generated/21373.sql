
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC, ws_quantity DESC) AS recent_sales_rank,
        SUM(ws_sales_price - ws_ext_discount_amt) OVER (PARTITION BY ws_item_sk) AS total_sales,
        AVG(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS average_profit,
        COUNT(DISTINCT ws_order_number) OVER (PARTITION BY ws_item_sk) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_item_sk IN (SELECT DISTINCT sr_item_sk
                        FROM store_returns 
                        WHERE sr_return_quantity > 0)
),
filtered_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.recent_sales_rank,
        rs.total_sales,
        rs.average_profit,
        rs.order_count
    FROM 
        ranked_sales rs
    WHERE 
        rs.recent_sales_rank = 1 AND 
        rs.total_sales IS NOT NULL AND 
        rs.average_profit > (SELECT AVG(rs2.average_profit) FROM ranked_sales rs2)
),
outer_joined_data AS (
    SELECT 
        fs.ws_item_sk,
        CASE 
            WHEN s.s_store_id IS NOT NULL THEN CONCAT(s.s_store_name, ' (In Store)')
            ELSE 'Online Only'
        END AS sales_channel,
        fs.total_sales,
        fs.order_count
    FROM 
        filtered_sales fs
    LEFT JOIN 
        store s ON fs.ws_item_sk = s.s_store_sk
)
SELECT 
    oj.sales_channel,
    COUNT(oj.ws_item_sk) AS item_count,
    SUM(oj.total_sales) AS total_sales_value,
    AVG(oj.order_count) AS average_orders_per_item
FROM 
    outer_joined_data oj
GROUP BY 
    oj.sales_channel
HAVING 
    SUM(oj.total_sales) > 1000 AND 
    COUNT(oj.ws_item_sk) > 5
ORDER BY 
    total_sales_value DESC;
