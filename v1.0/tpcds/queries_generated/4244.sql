
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    ti.i_item_desc,
    ti.total_sales,
    ti.i_current_price,
    cu.total_spent,
    CASE 
        WHEN cu.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Customer Active'
    END AS customer_status
FROM 
    top_items ti
LEFT JOIN 
    customer_data cu ON ti.ws_item_sk = cu.c_customer_sk
WHERE
    ti.total_sales > (SELECT AVG(total_sales) FROM ranked_sales)
ORDER BY 
    ti.total_sales DESC;
