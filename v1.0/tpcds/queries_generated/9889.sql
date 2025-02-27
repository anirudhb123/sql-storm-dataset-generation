
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_month_seq IN (4, 5) -- Considering sales in April and May
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    t.c_customer_id,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    t.item_count,
    COUNT(DISTINCT ws.ws_order_number) AS repeated_orders
FROM 
    TopCustomers t
LEFT JOIN 
    web_sales ws ON t.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = ws.ws_bill_customer_sk)
WHERE 
    t.sales_rank <= 10 -- Get top 10 customers
GROUP BY 
    t.c_customer_id, t.c_first_name, t.c_last_name, t.total_sales, t.order_count, t.item_count
ORDER BY 
    t.total_sales DESC;
