
WITH Address_Components AS (
    SELECT 
        ca_address_sk,
        CONCAT(trim(ca_street_number), ' ', trim(ca_street_name), ' ', trim(ca_street_type), 
            CASE 
                WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', trim(ca_suite_number))
                ELSE ''
            END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        CASE 
            WHEN d.cd_marital_status = 'M' THEN 'Married'
            WHEN d.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        d.cd_purchase_estimate,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        Address_Components a ON c.c_current_addr_sk = a.ca_address_sk
),
Benchmarking AS (
    SELECT 
        cs_borrower_sk,
        count(wp.web_page_sk) AS page_access_count,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(d.d_year) AS average_purchase_year
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN 
        Customer_Stats cs ON ws.ws_bill_customer_sk = cs.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.marital_status,
    cs.full_address,
    cs.ca_city,
    cs.ca_state,
    cs.ca_zip,
    cs.ca_country,
    b.page_access_count,
    b.total_spent,
    b.average_purchase_year
FROM 
    Customer_Stats cs
LEFT JOIN 
    Benchmarking b ON cs.c_customer_sk = b.cs_borrower_sk
WHERE 
    cs.cd_purchase_estimate > 50000
ORDER BY 
    b.total_spent DESC, cs.c_last_name ASC;
