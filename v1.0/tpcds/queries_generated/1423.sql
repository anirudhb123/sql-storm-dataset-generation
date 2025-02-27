
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        c.c_customer_id
),
return_summary AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.cr_return_amt_inc_tax) AS total_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '90 days')
    GROUP BY 
        cr.returning_customer_sk
),
combined_summary AS (
    SELECT 
        ss.c_customer_id,
        ss.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (ss.total_sales - COALESCE(rs.total_returns, 0)) AS net_sales
    FROM 
        sales_summary ss
    LEFT JOIN 
        return_summary rs ON ss.c_customer_id = rs.returning_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.total_returns,
    cs.net_sales,
    CASE 
        WHEN cs.net_sales > 1000 THEN 'High Value'
        WHEN cs.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    combined_summary cs
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.net_sales DESC;
