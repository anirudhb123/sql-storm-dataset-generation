
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ': ', ws.ws_ext_sales_price), '; ') AS purchased_items
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
Ranking AS (
    SELECT 
        customer_id,
        c_first_name,
        c_last_name,
        total_sales,
        order_count,
        purchased_items,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    customer_id,
    c_first_name,
    c_last_name,
    total_sales,
    order_count,
    purchased_items,
    sales_rank
FROM 
    Ranking
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;
