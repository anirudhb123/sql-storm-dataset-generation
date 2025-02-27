
WITH RecursivePromo AS (
    SELECT p.p_promo_sk, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk,
           ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY p.p_start_date_sk DESC) AS promo_rank
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
), 
CustomerReturns AS (
    SELECT sr_customer_sk, COUNT(*) AS total_returns, 
           SUM(sr_return_amt) AS total_return_amt,
           SUM(sr_return_quantity) AS total_return_qty
    FROM store_returns
    GROUP BY sr_customer_sk
), 
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           CASE 
               WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
               ELSE CASE 
                   WHEN cd.cd_purchase_estimate < 500 THEN 'Low'
                   WHEN cd.cd_purchase_estimate BETWEEN 500 AND 2000 THEN 'Medium'
                   ELSE 'High'
               END 
           END AS purchase_band
    FROM customer_demographics cd
), 
Inventories AS (
    SELECT inv.inv_warehouse_sk, SUM(inv.inv_quantity_on_hand) AS total_inv,
           COUNT(DISTINCT inv.inv_item_sk) AS item_count
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT ca.ca_city,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COALESCE(SUM(cr.total_return_amt), 0) AS total_return_amt,
       COUNT(DISTINCT c.c_customer_sk) AS total_customers,
       COUNT(DISTINCT i.i_item_sk) AS total_items,
       MAX(CASE 
           WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
           ELSE cd.cd_marital_status
       END) AS marital_status,
       STRING_AGG(DISTINCT rp.p_promo_name, ', ') AS active_promotions,
       MAX(i.i_current_price) AS max_item_price
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN Inventories i ON i.inv_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN RecursivePromo rp ON ws.ws_order_number IN (
    SELECT p.p_promo_sk
    FROM RecursivePromo p
    WHERE p.promo_rank = 1 AND p.p_end_date_sk >= ws.ws_sold_date_sk
)
WHERE ca.ca_state = 'CA' 
  AND ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY ca.ca_city
ORDER BY total_sales DESC
LIMIT 10;
