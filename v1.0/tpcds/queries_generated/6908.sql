
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20150101 AND 20151231
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_profit, 
           cs.order_count,
           RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT tc.c_customer_sk, 
       tc.c_first_name, 
       tc.c_last_name, 
       tc.total_profit, 
       tc.order_count
FROM TopCustomers tc
WHERE tc.profit_rank <= 10
ORDER BY tc.total_profit DESC;

-- Get the sales distribution by state and ship mode
SELECT ca.ca_state, 
       sm.sm_type, 
       SUM(ws.ws_net_paid_inc_tax) AS total_sales,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_sold_date_sk BETWEEN 20150101 AND 20151231
GROUP BY ca.ca_state, sm.sm_type
ORDER BY total_sales DESC;

-- Inventory availability with sales performance analysis
SELECT i.i_item_id, 
       i.i_item_desc, 
       inv.inv_quantity_on_hand,
       COALESCE(SUM(ws.ws_quantity), 0) AS total_sales_quantity,
       COALESCE(SUM(ws.ws_net_sales), 0) AS total_sales_value
FROM item i
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk AND ws.ws_sold_date_sk BETWEEN 20150101 AND 20151231
GROUP BY i.i_item_id, i.i_item_desc, inv.inv_quantity_on_hand
HAVING inv.inv_quantity_on_hand < 10
ORDER BY total_sales_value DESC;

-- Customer demographics correlation with sales
SELECT cd.cd_gender, 
       cd.cd_marital_status, 
       AVG(ws.ws_net_profit) AS avg_net_profit
FROM customer_demographics cd
JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ws.ws_sold_date_sk BETWEEN 20150101 AND 20151231
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY avg_net_profit DESC;
