
WITH RECURSIVE sales_ranking AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451911 AND 2452011
    GROUP BY 
        ws_item_sk
), 
top_products AS (
    SELECT 
        sr.ws_item_sk,
        i.i_item_desc,
        sr.total_profit,
        sr.profit_rank
    FROM 
        sales_ranking sr
    JOIN 
        item i ON sr.ws_item_sk = i.i_item_sk
    WHERE 
        sr.profit_rank <= 10
), 
customer_promotion AS (
    SELECT 
        c.c_customer_id,
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, p.p_promo_id
    HAVING 
        SUM(ws.ws_net_profit) > 5000
), 
warehouse_sales AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    tp.i_item_desc,
    tp.total_profit,
    cp.c_customer_id,
    cp.total_orders,
    cp.total_spent,
    ws.w_warehouse_name,
    ws.total_quantity_sold
FROM 
    top_products tp
LEFT JOIN 
    customer_promotion cp ON tp.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cp.c_customer_id)
JOIN 
    warehouse_sales ws ON ws.total_profit > 0
WHERE 
    tp.total_profit IS NOT NULL
ORDER BY 
    tp.total_profit DESC, cp.total_spent DESC;
