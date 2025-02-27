
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk
),
Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM Customer_Stats cs
    WHERE cs.order_count > 5
),
Inventory_Report AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE inv_date_sk = (
        SELECT MAX(inv_date_sk)
        FROM inventory
    )
    GROUP BY i.i_item_sk
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS store_sales_count,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
    s.store_name,
    i.total_on_hand
FROM customer c
LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN store st ON s.ss_store_sk = st.s_store_sk 
LEFT JOIN Inventory_Report i ON i.i_item_sk = s.ss_item_sk
WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM Top_Customers WHERE customer_rank <= 10)
GROUP BY c.c_customer_id, s.store_name, i.total_on_hand
ORDER BY total_store_profit DESC, total_web_profit DESC;
