
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50.00 AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws.web_site_sk, ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT 
    wa.w_warehouse_id AS warehouse_id,
    ca.ca_city AS city,
    COUNT(rs.ws_order_number) AS order_count,
    SUM(rs.total_quantity) AS aggregate_quantity,
    SUM(rs.total_sales) AS aggregate_sales
FROM RankedSales rs
JOIN warehouse wa ON rs.web_site_sk = wa.w_warehouse_sk
JOIN customer_address ca ON rs.ws_item_sk = ca.ca_address_sk
WHERE rs.rank <= 5
GROUP BY wa.w_warehouse_id, ca.ca_city
HAVING SUM(rs.total_sales) > 1000
ORDER BY aggregate_sales DESC;
