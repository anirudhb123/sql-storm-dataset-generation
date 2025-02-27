
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
)
SELECT 
    tc.customer_id,
    COALESCE(tc.total_sales, 0) AS total_sales,
    tc.order_count,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_category
FROM TopCustomers tc
WHERE tc.order_count > (
    SELECT AVG(order_count) 
    FROM TopCustomers
)
ORDER BY total_sales DESC;

-- Sales performance benchmark comparison with a specific condition
SELECT 
    sm.sm_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid_inc_tax) AS average_payment
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_year < 1980 AND
    ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY sm.sm_type
HAVING SUM(ws.ws_net_profit) > 10000;

-- Inventory check across multiple categories with optional filtering
SELECT 
    i.i_item_id,
    i.i_product_name,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    DENSE_RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS rank_within_category
FROM item i
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
WHERE 
    i.i_category IN (SELECT DISTINCT i_category FROM item WHERE i_rec_start_date <= CURDATE())
GROUP BY i.i_item_id, i.i_product_name
HAVING total_quantity IS NOT NULL
ORDER BY total_quantity DESC;

-- Store performance metrics comparison including correlation assessments
SELECT 
    s.s_store_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
    SUM(ss.ss_net_profit) AS net_profit,
    (SELECT AVG(ss_net_profit) FROM store_sales) AS average_store_profit,
    (SELECT COUNT(ss_ticket_number) FROM store_sales ss2 WHERE ss2.ss_store_sk != s.s_store_sk AND ss2.ss_net_profit > 0) AS other_successful_sales_count
FROM store s
JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
WHERE 
    s.s_manager IS NOT NULL
GROUP BY s.s_store_name
HAVING net_profit > (SELECT AVG(net_profit) FROM store_sales)
ORDER BY net_profit DESC;
