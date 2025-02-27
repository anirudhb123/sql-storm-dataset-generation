
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws.ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.total_sales,
        r.order_count
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
),
sales_details AS (
    SELECT 
        t.c_customer_id,
        i.i_item_desc,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price
    FROM 
        top_customers t
    JOIN 
        web_sales ws ON t.c_customer_id = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT 
    td.c_customer_id,
    SUM(sd.ws_ext_sales_price) AS total_spent,
    AVG(sd.ws_sales_price) AS average_item_price,
    COUNT(sd.ws_quantity) AS items_purchased
FROM 
    top_customers td
JOIN 
    sales_details sd ON td.c_customer_id = sd.c_customer_id
GROUP BY 
    td.c_customer_id
ORDER BY 
    total_spent DESC;
