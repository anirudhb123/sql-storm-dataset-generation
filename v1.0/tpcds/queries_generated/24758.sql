
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_order_number IN (
            SELECT cs_order_number 
            FROM catalog_sales 
            WHERE cs_ship_mode_sk IS NOT NULL
        )
),
HighValueItems AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        (rs.ws_sales_price * rs.ws_quantity) AS total_value,
        SUM(rs.ws_sales_price * rs.ws_quantity) OVER (PARTITION BY rs.ws_item_sk) AS overall_value
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    hv.ws_item_sk,
    hv.total_value,
    hv.overall_value,
    CASE 
        WHEN hv.total_value > 1000 THEN 'High Value'
        WHEN hv.total_value BETWEEN 500 AND 1000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS value_category,
    (SELECT COUNT(*) FROM store s WHERE s.s_state IN ('CA', 'NY')) AS store_count,
    COALESCE((SELECT MAX(ss.net_profit) 
              FROM store_sales ss 
              WHERE ss.ss_sold_date_sk = 
                  (SELECT MAX(d.d_date_sk) 
                   FROM date_dim d 
                   WHERE d.d_weekend = 'Y') 
              AND ss.ss_item_sk = hv.ws_item_sk), 0) AS max_profit_for_item
FROM 
    HighValueItems hv
JOIN 
    customer c ON c.c_customer_sk = hv.ws_order_number
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    hv.total_value > (SELECT AVG(hv.total_value) FROM HighValueItems hv)
ORDER BY 
    hv.total_value DESC, 
    c.c_customer_id ASC
LIMIT 500;
