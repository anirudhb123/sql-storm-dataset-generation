
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 90 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.bill_customer_sk
), CustomerDetail AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_birth_year,
        ca.ca_city,
        CASE 
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Other' 
        END AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), CombinedResults AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.marital_status,
        cd.ca_city,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rs.order_count, 0) AS order_count
    FROM 
        CustomerDetail cd
    LEFT JOIN 
        RankedSales rs ON cd.c_customer_sk = rs.bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CombinedResults
ORDER BY 
    total_sales DESC
LIMIT 50;
