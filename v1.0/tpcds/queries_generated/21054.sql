
WITH RECURSIVE customer_rankings AS (
    SELECT c_customer_sk, c_customer_id, 
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rnk
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
), 
sales_summary AS (
    SELECT ws.web_site_id, 
           SUM(ws.net_paid) AS total_net_paid,
           COUNT(DISTINCT ws.order_number) AS total_orders,
           AVG(ws.ext_ship_cost) AS avg_ship_cost,
           MAX(ws.net_profit) AS max_profit,
           MIN(ws.net_paid) AS min_paid
    FROM web_sales ws
    JOIN customer_address ca ON ws.bill_addr_sk = ca.ca_address_sk
    GROUP BY ws.web_site_id
), 
return_statistics AS (
    SELECT sr_item_sk,
           SUM(CASE WHEN sr_return_quantity IS NULL THEN 0 ELSE sr_return_quantity END) AS total_returns,
           AVG(sr_return_amt_inc_tax) AS avg_return_amt,
           COUNT(*) AS total_return_records
    FROM store_returns
    GROUP BY sr_item_sk
), 
product_details AS (
    SELECT i.item_id,
           i.item_desc,
           COALESCE(CAST(i.current_price AS DECIMAL(10,2)), 0) AS current_price,
           (SELECT COUNT(*) FROM inventory inv WHERE inv.inv_item_sk = i.item_sk AND inv.inv_quantity_on_hand > 0) AS available_stock
    FROM item i
), 
final_analysis AS (
    SELECT cr.c_customer_id,
           cs.total_orders,
           ss.total_net_paid,
           ss.avg_ship_cost,
           CASE WHEN rs.total_returns > 0 THEN 'Returned' ELSE 'Not Returned' END AS return_status,
           pd.item_desc,
           pd.current_price,
           pd.available_stock
    FROM customer_rankings cr
    LEFT JOIN sales_summary ss ON ss.total_orders BETWEEN 5 AND 10
    LEFT JOIN return_statistics rs ON rs.total_return_records > 0
    JOIN product_details pd ON pd.current_price > 20.00
    WHERE cr.rnk <= 100 AND (cr.c_customer_id IS NOT NULL OR cr.c_customer_id IS NOT NULL)
)
SELECT fa.*,
       RANK() OVER (PARTITION BY fa.return_status ORDER BY fa.total_net_paid DESC) AS rank_within_status,
       CONCAT('Customer: ', fa.c_customer_id, ' - Status: ', fa.return_status) AS customer_status
FROM final_analysis fa
ORDER BY fa.return_status, fa.total_net_paid DESC;
