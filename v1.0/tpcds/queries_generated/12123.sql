
SELECT SUM(ws_ext_sales_price) AS total_sales, 
       COUNT(DISTINCT ws_order_number) AS total_orders, 
       AVG(ws_net_profit) AS average_profit
FROM web_sales
JOIN item ON ws_item_sk = i_item_sk
JOIN customer ON ws_bill_customer_sk = c_customer_sk
JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
WHERE cd_gender = 'M' 
  AND cd_marital_status = 'M' 
  AND d_year = 2023
GROUP BY c_customer_id
ORDER BY total_sales DESC
LIMIT 100;
