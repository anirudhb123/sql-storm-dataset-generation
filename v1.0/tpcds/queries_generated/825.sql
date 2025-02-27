
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_orders,
    COALESCE((
        SELECT AVG(inv.inv_quantity_on_hand)
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        WHERE inv.inv_quantity_on_hand < (SELECT AVG(inv_quantity_on_hand) FROM inventory)
    ), 0) AS avg_inventory_below_threshold,
    (SELECT COUNT(DISTINCT sr_ticket_number) 
     FROM store_returns sr 
     WHERE sr.sr_returned_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_month_seq = (
            SELECT d_month_seq 
            FROM date_dim 
            WHERE d.d_date_sk = CURRENT_DATE
        )
     )
    ) AS total_returns
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_web_sales DESC;
