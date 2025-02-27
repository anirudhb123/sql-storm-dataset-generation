
WITH recent_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        it.i_current_price IS NOT NULL AND 
        ws.ws_net_profit IS NOT NULL AND 
        it.i_rec_end_date IS NULL
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > 10000
),
low_stock_items AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        total_stock < 10
),
item_promotions AS (
    SELECT 
        p.p_promo_name,
        p.p_item_sk,
        COUNT(p.p_promo_sk) AS promo_count
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name, p.p_item_sk
),
final_report AS (
    SELECT 
        r.web_site_id,
        r.ws_item_sk,
        COALESCE(c.c_customer_id, 'No high value customers') AS customer_id,
        COALESCE(hvc.total_spent, 0) AS high_value_spent,
        COALESCE(lsi.total_stock, 'Out of stock') AS stock_status,
        ip.promo_count AS active_promotions
    FROM 
        recent_sales r
    LEFT JOIN 
        high_value_customers hvc ON r.web_site_id = hvc.c_customer_id
    LEFT JOIN 
        low_stock_items lsi ON r.ws_item_sk = lsi.inv_item_sk
    LEFT JOIN 
        item_promotions ip ON r.ws_item_sk = ip.p_item_sk
    WHERE 
        r.sales_rank <= 10 
    OR 
        r.ws_net_profit IS NULL
)
SELECT 
    * 
FROM 
    final_report
WHERE 
    high_value_spent > 0 OR active_promotions > 0
ORDER BY 
    web_site_id, ws_item_sk;
