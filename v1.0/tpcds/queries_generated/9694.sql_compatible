
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_item_sk, ws.ws_order_number, ws.ws_ship_date_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(rs.total_sales) AS customer_total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders
    FROM 
        ranked_sales rs
    JOIN 
        customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
customer_ranked AS (
    SELECT 
        c.customer_total_sales,
        c.total_orders,
        RANK() OVER (ORDER BY c.customer_total_sales DESC) AS sales_rank
    FROM 
        customer_sales c
)
SELECT 
    cr.sales_rank,
    cr.customer_total_sales,
    cr.total_orders
FROM 
    customer_ranked cr
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.sales_rank;
