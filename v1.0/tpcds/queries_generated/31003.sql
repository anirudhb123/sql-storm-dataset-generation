
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        w.ws_sold_date_sk,
        w.ws_item_sk,
        w.ws_quantity,
        w.ws_sales_price,
        w.ws_net_profit,
        sd.level + 1
    FROM 
        web_sales w
    JOIN 
        sales_data sd ON w.ws_sold_date_sk = sd.ws_sold_date_sk - 1 AND w.ws_item_sk = sd.ws_item_sk
    WHERE 
        sd.level < 5
),
item_sales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sd.ws_net_profit), 0) AS customer_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT 
    isales.i_item_id,
    isales.i_product_name,
    isales.total_quantity,
    isales.total_net_profit,
    csales.c_customer_id,
    csales.c_first_name,
    csales.c_last_name,
    csales.customer_profit,
    CASE 
        WHEN csales.customer_profit IS NULL THEN 'No Sales'
        WHEN csales.customer_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM 
    item_sales isales
FULL OUTER JOIN 
    customer_sales csales ON isales.total_quantity >= 5 AND csales.customer_profit > 1000
WHERE 
    isales.total_net_profit > 0 OR csales.customer_profit > 0
ORDER BY 
    isales.total_net_profit DESC NULLS LAST, 
    csales.customer_profit DESC NULLS LAST;
