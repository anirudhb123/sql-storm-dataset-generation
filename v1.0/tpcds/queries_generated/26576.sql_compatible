
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_street_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr.'
            WHEN cd_gender = 'F' THEN 'Ms.'
            ELSE ''
        END AS salutation
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        ci.salutation,
        ai.ca_city,
        ai.ca_state,
        COALESCE(rs.total_sales, 0) AS recent_total_sales,
        COALESCE(rs.order_count, 0) AS recent_order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        RecentSales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN 
        customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        AddressInfo ai ON ai.ca_address_sk = ca.ca_address_sk
)
SELECT 
    full_name,
    salutation,
    ca_city,
    ca_state,
    recent_total_sales,
    recent_order_count,
    CASE 
        WHEN recent_total_sales = 0 THEN 'No recent purchases'
        WHEN recent_total_sales < 100 THEN 'Low spender'
        ELSE 'Frequent buyer'
    END AS customer_segment
FROM 
    FinalReport
ORDER BY 
    recent_total_sales DESC, full_name;
