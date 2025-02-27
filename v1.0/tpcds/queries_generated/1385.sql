
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        DENSE_RANK() OVER (ORDER BY total_net_paid DESC) AS customer_rank,
        rs.total_quantity,
        rs.total_net_paid
    FROM 
        customer c
    JOIN 
        ranked_sales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.rank <= 5
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_net_paid,
    id.i_item_id,
    id.i_product_name,
    id.i_current_price,
    id.i_brand,
    id.i_category
FROM 
    top_customers tc
LEFT JOIN 
    item_details id ON tc.total_quantity = (SELECT SUM(ws_quantity) FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_id AND ws_item_sk = id.i_item_id)
WHERE 
    tc.total_net_paid > (SELECT AVG(ws_net_paid) FROM web_sales)
ORDER BY 
    tc.customer_rank,
    tc.total_net_paid DESC;
