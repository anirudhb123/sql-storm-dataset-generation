
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_web_site_sk
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk, ws_web_site_sk
    HAVING
        SUM(ws_quantity) > 10
    UNION ALL
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_sales_price) AS total_sales,
        w.web_site_sk
    FROM 
        store_sales s
    JOIN 
        warehouse w ON s.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        s.ss_sold_date_sk, s.ss_item_sk, w.web_site_sk
    HAVING
        SUM(s.ss_quantity) > 5
),
item_ranked AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_web_site_sk ORDER BY sd.total_sales DESC) AS rank,
        sd.total_sales,
        sd.total_quantity
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
),
customer_activity AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(ws.ws_order_number) > 0
)
SELECT 
    ca.c_first_name,
    ca.c_last_name,
    ir.i_item_desc,
    ir.total_sales,
    ir.total_quantity,
    COALESCE(ca.total_spent, 0) AS customer_spending,
    ROW_NUMBER() OVER (ORDER BY ir.total_sales DESC) AS sales_rank
FROM 
    item_ranked ir
LEFT JOIN 
    customer_activity ca ON ir.rank <= 10 -- Top 10 items ranked
WHERE 
    ir.total_sales IS NOT NULL
ORDER BY 
    ir.total_sales DESC;
