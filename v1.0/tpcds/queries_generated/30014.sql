
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) as rank
    FROM web_sales
    WHERE ws_sold_date_sk > (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_date = CURRENT_DATE - INTERVAL '30 days'
    )
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        SalesCTE.total_quantity,
        SalesCTE.total_net_profit
    FROM SalesCTE
    JOIN item ON SalesCTE.ws_item_sk = item.i_item_sk
    WHERE SalesCTE.total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM SalesCTE
    )
)
SELECT 
    customer.c_customer_id,
    customer.c_first_name, 
    customer.c_last_name,
    COALESCE(SUM(ws.net_paid_inc_tax), 0) AS total_spent,
    COUNT(DISTINCT FS.i_item_id) AS unique_items_purchased
FROM customer
LEFT JOIN web_sales ws ON customer.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN FilteredSales FS ON ws.ws_item_sk = FS.i_item_sk
GROUP BY customer.c_customer_id, customer.c_first_name, customer.c_last_name
HAVING total_spent > (
    SELECT AVG(total_spent)
    FROM (
        SELECT SUM(ws_net_paid_inc_tax) as total_spent
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) AS avg_spent
)
ORDER BY total_spent DESC
LIMIT 100;
