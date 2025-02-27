
WITH RECURSIVE DateCTE AS (
    SELECT d_date_sk, d_date_id, d_date, d_year, d_month_seq, d_week_seq
    FROM date_dim
    WHERE d_year = 2023
    
    UNION ALL
    
    SELECT d.d_date_sk, d.d_date_id, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq
    FROM date_dim d
    INNER JOIN DateCTE ON d.d_date_sk = DateCTE.d_date_sk + 1
    WHERE d.d_year = 2023
), 
CustomerCTE AS (
    SELECT c.c_customer_sk, c.c_last_name, c.c_first_name, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, ca.ca_city, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
), 
SalesSummary AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold, 
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN CustomerCTE cc ON ws.ws_ship_customer_sk = cc.c_customer_sk
    GROUP BY ws.ws_item_sk
), 
RankedSales AS (
    SELECT ss.total_quantity_sold, ss.total_net_profit, ss.total_orders, 
           DENSE_RANK() OVER (ORDER BY ss.total_net_profit DESC) AS profit_rank
    FROM SalesSummary ss
)
SELECT 
    d.d_date AS sales_date,
    r.total_quantity_sold,
    r.total_net_profit,
    CASE 
        WHEN r.total_orders > 100 THEN 'High Activity'
        WHEN r.total_orders IS NULL THEN 'No Sales'
        ELSE 'Low Activity'
    END AS sales_activity,
    string_agg(DISTINCT CONCAT(cc.c_last_name, ', ', cc.c_first_name) ORDER BY cc.c_last_name) AS customers
FROM DateCTE d
LEFT JOIN RankedSales r ON d.d_date_sk = (SELECT ws_sold_date_sk FROM web_sales ws WHERE ws.ws_item_sk = r.ws_item_sk LIMIT 1)
LEFT JOIN CustomerCTE cc ON cc.purchase_rank <= 10
WHERE r.total_net_profit IS NOT NULL
  AND (r.total_quantity_sold > 0 OR r.total_orders IS NULL)
GROUP BY d.d_date, r.total_quantity_sold, r.total_net_profit
ORDER BY d.d_date DESC, r.total_net_profit DESC
LIMIT 50;
