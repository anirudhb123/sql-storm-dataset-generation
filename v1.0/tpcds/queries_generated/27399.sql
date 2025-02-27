
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name || ' ' || c.c_last_name AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date >= CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        ws_bill_customer_sk
),
SalesRanking AS (
    SELECT 
        cs.c_customer_id,
        cs.full_name,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.total_orders, 0) AS total_orders,
        RANK() OVER (ORDER BY COALESCE(rs.total_sales, 0) DESC) AS sales_rank
    FROM 
        CustomerDetails cs
    LEFT JOIN 
        RecentSales rs ON cs.c_customer_id = rs.ws_bill_customer_sk
)
SELECT 
    sr.sales_rank,
    sr.full_name,
    sr.total_sales,
    sr.total_orders,
    CASE 
        WHEN sr.total_sales >= 1000 THEN 'High Value Customer'
        WHEN sr.total_sales >= 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM 
    SalesRanking sr
WHERE 
    sr.total_orders > 0
ORDER BY 
    sr.sales_rank;
