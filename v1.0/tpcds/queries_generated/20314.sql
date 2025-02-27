
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_order_number,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 1000
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN s.ss_quantity IS NOT NULL THEN s.ss_quantity ELSE 0 END) AS total_store_quantity,
        SUM(CASE WHEN w.ws_quantity IS NOT NULL THEN w.ws_quantity ELSE 0 END) AS total_web_quantity,
        c.c_first_name,
        c.c_last_name
    FROM customer c
    LEFT JOIN store_sales s ON s.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales w ON w.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(COALESCE(s.ss_quantity, 0) + COALESCE(w.ws_quantity, 0)) > 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT cp.cr_order_number) AS total_catalog_returns,
    SUM(cp.cr_return_amount) AS total_return_amount,
    SUM(sales_data.ws_sales_price * sales_data.ws_quantity) AS total_sales_value,
    COALESCE(inventory_check.total_on_hand, 0) AS inventory_available,
    CASE 
        WHEN sales_data.profit_rank = 1 THEN 'Top Performer'
        WHEN sales_data.profit_rank <= 3 THEN 'High Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM customer_purchases cp
LEFT JOIN store_returns sr ON cp.c_customer_sk = sr.sr_customer_sk
LEFT JOIN sales_data ON cp.c_customer_sk = sales_data.ws_item_sk
LEFT JOIN inventory_check ON sales_data.ws_item_sk = inventory_check.inv_item_sk
FULL OUTER JOIN customer c ON c.c_customer_sk = cp.c_customer_sk
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    inventory_check.total_on_hand,
    sales_data.profit_rank
HAVING 
    SUM(sales_data.ws_sales_price * sales_data.ws_quantity) > 5000
ORDER BY 
    total_sales_value DESC, 
    total_return_amount ASC;
