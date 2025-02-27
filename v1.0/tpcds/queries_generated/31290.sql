
WITH RECURSIVE sales_ranking AS (
    SELECT 
        ws.item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        DENSE_RANK() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.item_sk
), filtered_sales AS (
    SELECT
        sr.item_sk,
        sr.total_quantity,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        sales_ranking sr
    JOIN 
        item i ON sr.item_sk = i.i_item_sk
    WHERE 
        sr.rank <= 10
), customer_return_data AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS return_count,
        SUM(sr_return_amt) as total_return_amt
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
), active_customers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(ws.ws_order_number) > 5
), customer_summary AS (
    SELECT 
        ac.c_customer_sk,
        COALESCE(crd.return_count, 0) AS returns,
        COALESCE(crd.total_return_amt, 0) AS return_amt,
        ac.total_orders,
        ac.total_spent
    FROM 
        active_customers ac
    LEFT JOIN 
        customer_return_data crd ON ac.c_customer_sk = crd.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.returns,
    cs.return_amt,
    cs.total_orders,
    cs.total_spent,
    f.total_quantity,
    f.i_item_desc,
    f.i_current_price,
    f.i_brand
FROM 
    customer_summary cs
JOIN 
    filtered_sales f ON cs.total_orders > f.total_quantity
ORDER BY 
    cs.total_spent DESC;
