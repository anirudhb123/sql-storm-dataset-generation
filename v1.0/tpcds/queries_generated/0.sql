
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_order_number) AS cumulative_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year > 1980
),
sales_summary AS (
    SELECT 
        web_site_id,
        COUNT(ws_order_number) as total_orders,
        AVG(ws_sales_price) as average_order_value
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_id
),
returns_summary AS (
    SELECT 
        wr_returned_date_sk,
        SUM(wr_return_quantity) as total_returns,
        SUM(wr_return_amt) as total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr_returned_date_sk
),
comparison AS (
    SELECT 
        ss.web_site_id,
        ss.total_orders,
        ss.average_order_value,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt
    FROM 
        sales_summary ss
    LEFT JOIN 
        returns_summary rs ON ss.web_site_id = rs.wr_returned_date_sk
)
SELECT 
    c.web_site_id,
    c.total_orders,
    c.average_order_value,
    c.total_returns,
    c.total_return_amt,
    CASE 
        WHEN c.total_returns > 0 THEN ROUND((c.total_return_amt / (c.total_orders * c.average_order_value)) * 100, 2)
        ELSE 0 
    END AS return_rate_percentage
FROM 
    comparison c
WHERE 
    c.average_order_value IS NOT NULL
ORDER BY 
    return_rate_percentage DESC;
