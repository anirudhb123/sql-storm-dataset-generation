
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_sales,
        COUNT(*) OVER (PARTITION BY ws.ws_item_sk) AS sales_count
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
        AND (ws.ws_sales_price IS NOT NULL OR ws.ws_sales_price > 0)
        AND EXISTS (
            SELECT 1 
            FROM store s 
            WHERE s.s_store_sk = (SELECT MIN(s_store_sk) FROM store WHERE s_number_employees > 0)
        )
),
sales_summary AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS order_total,
        MAX(rs.ws_sales_price) AS max_price,
        MIN(rs.ws_sales_price) AS min_price
    FROM 
        ranked_sales rs
    WHERE 
        rs.price_rank <= 5
    GROUP BY 
        rs.ws_order_number
),
customer_avg AS (
    SELECT 
        c.c_customer_id,
        AVG(CASE WHEN cd.cd_marital_status = 'M' THEN ws.ws_sales_price ELSE NULL END) AS avg_married_spending,
        AVG(CASE WHEN cd.cd_marital_status = 'S' THEN ws.ws_sales_price ELSE NULL END) AS avg_single_spending
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    c.c_customer_id,
    COALESCE(ca.ca_state, 'Unknown') AS customer_state,
    cs.order_total,
    cs.max_price,
    cs.min_price,
    ca.ca_city,
    (SELECT COUNT(*) FROM inventory i WHERE i.inv_quantity_on_hand = 0) AS out_of_stock_items,
    cu.avg_married_spending,
    cu.avg_single_spending
FROM 
    sales_summary cs
JOIN 
    customer c ON cs.ws_order_number = (SELECT MIN(ws_order_number) FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_avg cu ON c.c_customer_id = cu.c_customer_id
WHERE 
    (cu.avg_married_spending > 100 OR cu.avg_single_spending > 100)
    AND (cs.order_total IS NOT NULL AND cs.order_total > 0)
ORDER BY 
    cs.order_total DESC;
