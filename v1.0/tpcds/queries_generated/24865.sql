
WITH RECURSIVE price_calculation AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        (i.i_current_price * (1 - COALESCE(AVG(pr.p_discount_active::int)/100, 0))) AS adjusted_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY i.i_current_price DESC) AS price_rank
    FROM 
        item i
    LEFT JOIN 
        promotion pr ON i.i_item_sk = pr.p_item_sk AND pr.p_discount_active = 'Y'
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    p.i_item_sk,
    p.i_item_desc,
    p.adjusted_price,
    COALESCE(sd.total_sales_price, 0) AS total_sales_price,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    MAX(sd.total_sales_price) OVER (PARTITION BY p.i_item_sk) AS max_sales_price,
    CASE 
        WHEN p.adjusted_price IS NULL THEN 'Price Not Available'
        WHEN sd.total_sales_price IS NULL THEN 'Sales Data Missing'
        ELSE 'Data Available'
    END AS data_status
FROM 
    price_calculation p
FULL OUTER JOIN 
    sales_data sd ON p.i_item_sk = sd.ws_item_sk
WHERE 
    p.price_rank <= 5 AND 
    (sd.total_orders IS NULL OR sd.total_quantity > 10)
ORDER BY 
    p.i_item_desc ASC, p.adjusted_price DESC;
