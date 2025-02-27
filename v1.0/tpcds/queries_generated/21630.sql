
WITH RECURSIVE customer_return_stats AS (
    SELECT 
        ca.ca_address_id, 
        c.c_customer_id, 
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY ca.ca_address_id, c.c_customer_id
    
    UNION ALL

    SELECT 
        ca.ca_address_id,
        c.c_customer_id,
        cr.total_returns + 1,
        cr.total_returned_quantity + sr.return_quantity,
        cr.total_returned_amount + sr.return_amt
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    JOIN customer_return_stats cr ON cr.ca_address_id = ca.ca_address_id
    WHERE sr.sr_returned_date_sk = cr.total_returns + 1
)

SELECT 
    address.ca_address_id,
    address.ca_city,
    demo.cd_gender,
    demo.cd_marital_status,
    MAX(rs.total_returns) AS max_total_returns,
    AVG(rs.total_returned_quantity) AS avg_returned_quantity,
    CASE 
        WHEN MAX(rs.total_returned_amount) IS NULL THEN 'No Returns'
        ELSE CONCAT('Total Amount Returned: $', MAX(rs.total_returned_amount))
    END AS return_summary,
    CUBE(demo.cd_marital_status, demo.cd_gender) 
    WITH ROLLUP AS (
        SELECT 
            cd_marital_status, 
            cd_gender, 
            COUNT(*) as count
        FROM customer_demographics demo
        GROUP BY CUBE(cd_marital_status, cd_gender)
    )
FROM customer_return_stats rs
JOIN customer_demographics demo ON rs.c_customer_id = demo.cd_demo_sk
JOIN customer_address address ON address.ca_address_id = rs.ca_address_id
GROUP BY address.ca_address_id, address.ca_city, demo.cd_gender, demo.cd_marital_status
ORDER BY max_total_returns DESC
LIMIT 10;

-- Ensure that the null logic is working properly
SELECT 
    w.w_warehouse_id,
    COALESCE(w.w_warehouse_name, 'Unnamed Warehouse') AS warehouse_name,
    COALESCE(COUNT(ws.ws_item_sk), 0) AS total_sales_items,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders
FROM warehouse w
LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
WHERE 
    w.w_warehouse_sq_ft > 1000 AND 
    NOT EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_sold_date_sk = CURRENT_DATE - INTERVAL '1 day' 
        AND ss.ss_store_sk = w.w_warehouse_sk
    )
GROUP BY w.w_warehouse_id, warehouse_name
HAVING total_sales_items IN (SELECT MAX(total_sales_items) FROM (SELECT COUNT(ws_item_sk) as total_sales_items FROM web_sales GROUP BY ws_warehouse_sk) as subquery)
ORDER BY unique_orders DESC;

