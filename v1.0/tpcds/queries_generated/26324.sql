
WITH Address_City AS (
    SELECT ca_address_sk, ca_city
    FROM customer_address
), 
Customer_Info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        a.ca_city,
        c.c_preferred_cust_flag,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS purchase_rank
    FROM customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 
),
Filtered_Customers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.city,
        c.preferred_cust_flag
    FROM Customer_Info c
    WHERE c.purchase_rank = 1 
      AND c.city IS NOT NULL 
      AND c.preferred_cust_flag = 'Y'
),
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    f.customer_id,
    f.first_name,
    f.last_name,
    f.city AS customer_city,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status
FROM Filtered_Customers f
JOIN Customer_Demographics d ON f.customer_id = d.cd_demo_sk
ORDER BY f.last_name, f.first_name;
