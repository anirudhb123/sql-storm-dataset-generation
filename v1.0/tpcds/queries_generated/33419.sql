
WITH RECURSIVE Customer_CTE AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, c.c_birth_year,
           ROW_NUMBER() OVER (PARTITION BY c.c_current_addr_sk ORDER BY c.c_birth_year DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, c.c_birth_year,
           ROW_NUMBER() OVER (PARTITION BY c.c_current_addr_sk ORDER BY c.c_birth_year DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND c.c_birth_year < (SELECT MAX(c2.c_birth_year) FROM customer c2 WHERE c2.c_current_addr_sk = c.c_current_addr_sk)
      AND rnk < 5
),
Sales_Summary AS (
    SELECT ws.ws_bill_customer_sk,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_profit,
           AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
Inventory_Status AS (
    SELECT inv.inv_item_sk,
           SUM(inv.inv_quantity_on_hand) AS total_quantity,
           COUNT(DISTINCT inv.inv_warehouse_sk) AS unique_warehouses
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
Shipping_Info AS (
    SELECT wr.wr_web_page_sk,
           SUM(wr.wr_return_quantity) AS total_returns,
           SUM(wr.wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns wr
    GROUP BY wr.wr_web_page_sk
)
SELECT ccte.c_first_name,
       ccte.c_last_name,
       SUM(COALESCE(ss.total_orders, 0)) AS orders,
       SUM(COALESCE(ss.total_profit, 0)) AS profit,
       AVG(COALESCE(ss.avg_net_paid, 0)) AS avg_payment,
       SUM(COALESCE(is.total_quantity, 0)) AS inventory,
       SUM(COALESCE(si.total_returns, 0)) AS returns,
       SUM(COALESCE(si.total_return_value, 0)) AS return_value
FROM Customer_CTE ccte
LEFT JOIN Sales_Summary ss ON ccte.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN Inventory_Status is ON ccte.c_current_addr_sk IN (
    SELECT ca_address_sk FROM customer_address WHERE ca_address_sk IS NOT NULL
)
LEFT JOIN Shipping_Info si ON si.wr_web_page_sk IN (
    SELECT wp_web_page_sk FROM web_page WHERE wp_web_page_sk IS NOT NULL
)
GROUP BY ccte.c_first_name, ccte.c_last_name
HAVING SUM(COALESCE(ss.total_profit, 0)) > 1000
ORDER BY profit DESC
LIMIT 10;
