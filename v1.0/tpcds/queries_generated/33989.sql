
WITH RECURSIVE ReturnedSales AS (
    SELECT sr.returned_date_sk, sr.return_time_sk, sr.item_sk, sr.customer_sk, sr.cdemo_sk,
           sr.return_quantity, sr.return_amt, sr.return_tax, sr.return_amt_inc_tax,
           sr.ticket_number, 1 AS level
    FROM store_returns sr
    WHERE sr.returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT sr.returned_date_sk, sr.return_time_sk, sr.item_sk, sr.customer_sk, sr.cdemo_sk,
           sr.return_quantity * 2, sr.return_amt * 2, sr.return_tax * 2, sr.return_amt_inc_tax * 2,
           sr.ticket_number, level + 1
    FROM store_returns sr
    INNER JOIN ReturnedSales rs ON sr.item_sk = rs.item_sk AND rs.level < 3
)

SELECT ca.country, 
       SUM(ws.ws_ext_sales_price) AS total_sales, 
       SUM(rs.return_amt) AS total_returns,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       ROUND(AVG(ws.ws_net_profit), 2) AS avg_net_profit,
       MAX(ws.ws_ext_discount_amt) AS max_discount,
       COUNT(*) FILTER (WHERE ws.ws_net_profit < 0) AS net_loss_orders
FROM web_sales ws
LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN ReturnedSales rs ON ws.ws_item_sk = rs.item_sk
WHERE ca.ca_country IS NOT NULL 
  AND ws.ws_sales_price > 0
  AND (EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = ws.ws_warehouse_sk AND s.s_state = 'CA')
       OR NOT EXISTS (SELECT 1 FROM ship_mode sm WHERE sm.sm_ship_mode_sk = ws.ws_ship_mode_sk))
GROUP BY ca.country
ORDER BY total_sales DESC
LIMIT 10;
