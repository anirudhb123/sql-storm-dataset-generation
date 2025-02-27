
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
),
customer_orders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(co.total_spent, 0) AS total_spent,
        RANK() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_orders co ON c.c_customer_sk = co.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
),
high_value_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
    HAVING 
        AVG(ws.ws_sales_price) > (
            SELECT 
                AVG(ws_sales_price) 
            FROM 
                web_sales
        )
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    t.total_spent,
    i.i_item_desc,
    r.price_rank,
    h.avg_sales_price
FROM 
    top_customers t
JOIN 
    ranked_sales r ON t.total_spent > 200
JOIN 
    high_value_items h ON r.ws_item_sk = h.i_item_sk
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    t.customer_rank <= 10
ORDER BY 
    t.total_spent DESC, h.avg_sales_price DESC;
