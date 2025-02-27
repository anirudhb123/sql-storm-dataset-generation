
WITH RECURSIVE ad_hoc_sales AS (
    SELECT 
        ss_customer_sk, 
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_tickets,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 -- Assume a range of 30 days
    GROUP BY 
        ss_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        COALESCE(SUM(ws.ws_net_paid), 0) AS online_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS store_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_credit_rating, ca.ca_city
),
sales_data AS (
    SELECT 
        ci.*, 
        (online_sales + store_sales) AS total_sales,
        CASE 
            WHEN total_sales > 100000 THEN 'High Value'
            WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_info ci
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
    WHERE 
        customer_value = 'High Value' 
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    c.ca_city,
    c.cd_credit_rating,
    CASE
        WHEN td.sales_rank IS NULL THEN 'Not Ranked'
        ELSE 'Ranked ' || td.sales_rank
    END AS sales_rank,
    c.total_sales
FROM 
    sales_data c 
LEFT JOIN 
    top_customers td ON c.c_customer_id = td.c_customer_id
WHERE 
    (SELECT COUNT(*) FROM top_customers WHERE customer_value = 'High Value') > 10 
    AND (c.cd_credit_rating IS NOT NULL OR c.ca_city IS NULL)
ORDER BY 
    c.total_sales DESC
LIMIT 10
OFFSET 5
UNION ALL
SELECT 
    'Total' AS full_name,
    NULL AS ca_city,
    NULL AS cd_credit_rating,
    NULL AS sales_rank,
    SUM(total_sales) 
FROM 
    sales_data 
WHERE 
    customer_value = 'Low Value' AND total_sales IS NOT NULL
GROUP BY 
    1
HAVING 
    SUM(total_sales) > 1000;
