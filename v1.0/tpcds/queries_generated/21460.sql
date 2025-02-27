
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city,
           CASE WHEN ca_zip IS NULL THEN 'Unknown' ELSE ca_zip END AS ZipCode,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS AddressRank
    FROM customer_address
    WHERE ca_country = 'USA'
), 
IncomeStats AS (
    SELECT hd_demo_sk, 
           SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS MaleCount,
           SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS SingleCount,
           AVG(cd_purchase_estimate) AS AvgPurchaseEstimate
    FROM household_demographics hd 
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY hd_demo_sk
), 
SalesAggregate AS (
    SELECT ws.web_site_id, 
           SUM(ws.ws_net_profit) AS TotalProfit, 
           COUNT(DISTINCT ws.ws_order_number) AS TotalOrders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = '1')
    GROUP BY ws.web_site_id
)
SELECT a.ZipCode, 
       i.MaleCount, 
       i.SingleCount, 
       i.AvgPurchaseEstimate, 
       s.TotalProfit, 
       COALESCE(s.TotalOrders, 0) AS TotalOrders,
       CASE
           WHEN s.TotalOrders > 100 THEN 'High Volume'
           WHEN s.TotalOrders BETWEEN 50 AND 100 THEN 'Medium Volume'
           ELSE 'Low Volume'
       END AS OrderVolume
FROM AddressCTE a
LEFT JOIN IncomeStats i ON a.AddressRank = 1
FULL OUTER JOIN SalesAggregate s ON a.ca_address_id = s.web_site_id
WHERE (i.AvgPurchaseEstimate > 500 AND s.TotalProfit IS NOT NULL) OR
      (s.TotalProfit > 10000 AND i.SingleCount < 5) 
ORDER BY a.ZipCode DESC NULLS LAST, 
         i.MaleCount DESC, 
         s.TotalProfit ASC;
