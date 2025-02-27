
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws_sold_date_sk, 
        ws_quantity, 
        ws_sales_price, 
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021)
      AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT CASE WHEN ws.web_site_sk IS NOT NULL THEN ws.ws_order_number END) AS total_orders,
        COUNT(DISTINCT ws.web_site_sk) AS unique_websites,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue 
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year BETWEEN 2020 AND 2022)
    GROUP BY i.i_item_sk
),
suspicious_returns AS (
    SELECT 
        sr.*, 
        COALESCE(cr.cr_return_quantity, 0) AS catalog_return_qty,
        COALESCE(sr_return_quantity, 0) + COALESCE(cr.cr_return_quantity, 0) AS total_returned_qty
    FROM store_returns sr
    LEFT JOIN catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk AND sr.sr_ticket_number = cr.cr_order_number
    WHERE (sr_return_quantity < 0 OR COALESCE(cr.cr_return_quantity, 0) > 0)
),
combined_sales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    JOIN store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws.web_site_sk
    HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.unique_websites,
    cs.total_spent,
    is.total_quantity_sold,
    is.total_revenue,
    COALESCE(ss.total_returned_qty, 0) AS total_returns,
    bs.total_revenue AS benchmark_revenue,
    RANK() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_spent DESC) AS spending_rank
FROM customer_summary cs
JOIN item_sales is ON cs.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = (SELECT MIN(c_customer_id) FROM customer WHERE c_current_addr_sk IS NOT NULL))
LEFT JOIN suspicious_returns ss ON cs.c_customer_sk = ss.sr_customer_sk
LEFT JOIN combined_sales bs ON cs.total_spent < (SELECT AVG(total_revenue) FROM combined_sales)
WHERE cs.total_orders > 10
ORDER BY spending_rank, total_spent DESC, total_quantity_sold ASC;
