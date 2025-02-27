
WITH RECURSIVE sales_with_profit AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as item_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk 
                            FROM date_dim 
                            WHERE d_year = 2022)
),
top_sales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) - SUM(ws_ext_discount_amt) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        sales_with_profit
    WHERE 
        item_rank <= 5
    GROUP BY 
        ws_order_number, ws_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ts.ws_order_number,
        ts.total_quantity,
        ts.total_sales,
        ts.total_profit
    FROM 
        customer c
    JOIN 
        top_sales ts ON c.c_customer_sk = (
            SELECT 
                ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_order_number = ts.ws_order_number 
            LIMIT 1
        )
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(cs.total_sales), 0) AS total_sales_amount,
    COALESCE(SUM(cs.total_profit), 0) AS total_profit_amount,
    COUNT(DISTINCT ws_order_number) AS order_count
FROM 
    customer_sales cs
LEFT JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
HAVING 
    COUNT(DISTINCT ws_order_number) > 2
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
