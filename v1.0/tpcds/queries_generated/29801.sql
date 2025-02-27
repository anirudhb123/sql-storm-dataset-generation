
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_count,
        STRING_AGG(DISTINCT ca.ca_street_name || ' ' || ca.ca_street_number, ', ') AS address
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ps.total_quantity,
    ps.total_sales,
    ps.order_count,
    ci.dep_count,
    ci.college_count,
    ci.employed_count,
    CONCAT(ci.full_name, ': ', ' ' || ci.address) AS detailed_info
FROM 
    customer_info ci
LEFT JOIN 
    purchase_summary ps ON ci.c_customer_sk = ps.c_customer_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ps.total_sales > 1000
ORDER BY 
    ps.total_sales DESC, ci.full_name;
