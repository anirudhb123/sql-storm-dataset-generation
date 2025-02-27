
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs.cust_id AS customer_id,
        SUM(cs.cs_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cust_id ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank
    FROM 
        (SELECT 
            cs.bill_customer_sk AS cust_id, 
            cs.net_paid 
         FROM 
            catalog_sales cs 
         WHERE 
            cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
        UNION ALL
         SELECT 
            ws.bill_customer_sk AS cust_id, 
            ws.net_paid 
         FROM 
            web_sales ws 
         WHERE 
            ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
        ) cs
    GROUP BY 
        cs.cust_id
),
top_customers AS (
    SELECT 
        customer_id,
        total_sales 
    FROM 
        sales_hierarchy 
    WHERE 
        sales_rank <= 10
),
return_stats AS (
    SELECT 
        sr.sr_customer_sk AS customer_id,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    tc.customer_id, 
    tc.total_sales,
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_returned, 0) AS total_returned,
    COALESCE(rs.total_net_loss, 0) AS total_net_loss,
    CASE 
        WHEN COALESCE(rs.total_returned, 0) > 0 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM 
    top_customers tc
LEFT JOIN 
    return_stats rs ON tc.customer_id = rs.customer_id
ORDER BY 
    tc.total_sales DESC;
