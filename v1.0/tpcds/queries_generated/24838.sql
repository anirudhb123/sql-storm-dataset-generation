
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS highest_sale_price,
        AVG(ws.ws_ext_discount_amt) AS average_discount,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_web_pages
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales) 
        AND cs.order_count > 2
),
returns_summary AS (
    SELECT 
        COUNT(cr.returning_customer_sk) AS total_returns,
        AVG(cr.return_fee) AS average_return_fee,
        SUM(cr.return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.return_quantity > 0
        AND cr.returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_net_paid
    FROM 
        warehouse w
    JOIN 
        store s ON w.w_warehouse_sk = s.s_company_id
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.order_count,
    wp.w_warehouse_id,
    wp.total_profit,
    wp.total_orders,
    wp.average_net_paid,
    rs.total_returns,
    rs.average_return_fee,
    rs.total_return_amount
FROM 
    high_value_customers hvc
JOIN 
    warehouse_performance wp ON hvc.total_sales BETWEEN wp.total_profit/2 AND wp.total_profit
CROSS JOIN 
    returns_summary rs
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_sales DESC, wp.total_profit ASC;
