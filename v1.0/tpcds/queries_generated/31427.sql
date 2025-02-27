
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY ws.web_site_sk
),
WarehouseDetails AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    LEFT JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
),
TopWebsites AS (
    SELECT 
        s.web_site_sk,
        s.total_orders,
        s.total_profit
    FROM SalesData s
    WHERE s.rank <= 5
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
)
SELECT 
    w.w_warehouse_name,
    COALESCE(tws.total_orders, 0) AS total_orders,
    COALESCE(tws.total_profit, 0) AS total_profit,
    ca.ca_city,
    ca.customer_count
FROM WarehouseDetails w
LEFT JOIN TopWebsites tws ON w.w_warehouse_id = (SELECT MAX(ws.web_site_id) FROM web_site ws)
LEFT JOIN CustomerAddress ca ON ca.ca_address_sk = (SELECT MIN(c.c_current_addr_sk) FROM customer c)
WHERE w.total_inventory > 100 OR tws.total_profit > 10000
ORDER BY total_profit DESC, total_orders DESC
LIMIT 10;
