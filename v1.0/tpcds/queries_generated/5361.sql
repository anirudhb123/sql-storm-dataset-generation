
WITH ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        store s ON cs.cs_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA' 
        AND i.i_current_price > 10.00
        AND cs.cs_sold_date_sk BETWEEN 2458000 AND 2458005 -- Example date range
    GROUP BY 
        cs.cs_item_sk, 
        cs.cs_order_number
),
top_items AS (
    SELECT 
        r.cs_item_sk,
        r.total_quantity,
        r.total_sales
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(t.total_sales) AS customer_total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        top_items t ON ss.ss_item_sk = t.cs_item_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(t.total_sales) > 1000
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.customer_total_sales
FROM 
    customer_sales cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
ORDER BY 
    cs.customer_total_sales DESC
LIMIT 50;
