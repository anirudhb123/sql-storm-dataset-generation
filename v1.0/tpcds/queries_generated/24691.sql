
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 10
    GROUP BY 
        ss_store_sk, ss_item_sk
), 
avg_sales AS (
    SELECT 
        sd.ss_store_sk,
        AVG(sd.total_sales) OVER (PARTITION BY sd.ss_store_sk) AS avg_quantity
    FROM 
        sales_data sd
), 
return_stats AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (cd.cd_marital_status = 'M' AND cd.cd_dep_count > 2)
        OR (cd.cd_marital_status IS NULL)
), 
formatted_addresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country = 'USA'
)
SELECT 
    s.s_store_name,
    COALESCE(a.avg_quantity, 0) AS average_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0.00) AS total_return_value,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    fa.full_address
FROM 
    store s
LEFT JOIN 
    avg_sales a ON s.s_store_sk = a.ss_store_sk
LEFT JOIN 
    return_stats r ON s.s_store_sk = r.sr_store_sk
JOIN 
    customer_info ci ON ci.rn = 1
JOIN 
    formatted_addresses fa ON fa.ca_address_sk = ci.c_current_addr_sk
WHERE 
    (a.avg_quantity > 5 OR r.total_returns IS NULL)
ORDER BY 
    s.s_store_name;
