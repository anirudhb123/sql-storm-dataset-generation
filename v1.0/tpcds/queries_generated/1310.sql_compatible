
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    ss.total_sales,
    ss.order_count,
    COALESCE(rs.total_returned, 0) AS total_returned,
    COALESCE(rs.return_count, 0) AS return_count,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 0 THEN 'Has Sales'
        ELSE 'Unidentified'
    END AS sales_status
FROM 
    customer_details cd
LEFT JOIN 
    sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
LEFT JOIN 
    return_summary rs ON cd.c_customer_id = rs.wr_returning_customer_sk
WHERE 
    cd.rn = 1
AND 
    (cd.ca_state = 'CA' OR cd.ca_state IS NULL)
ORDER BY 
    sales_status DESC, cd.c_last_name, cd.c_first_name;
