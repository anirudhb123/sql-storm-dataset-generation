
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), top_customers AS (
    SELECT 
        s.c_customer_id,
        s.c_first_name,
        s.c_last_name,
        s.total_sales,
        s.orders_count,
        s.distinct_items,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS rank
    FROM 
        sales_summary s
), return_summary AS (
    SELECT 
        rr.wr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returned_date_sk
), combined_report AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.orders_count,
        tc.distinct_items,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        top_customers tc
    LEFT JOIN 
        return_summary rs ON rs.wr_returned_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cr.total_sales,
    cr.orders_count,
    cr.distinct_items,
    cr.total_returns,
    cr.total_return_amount,
    ROUND((cr.total_sales - cr.total_return_amount), 2) AS net_sales
FROM 
    combined_report cr
WHERE 
    cr.rank <= 10
ORDER BY 
    cr.total_sales DESC;
