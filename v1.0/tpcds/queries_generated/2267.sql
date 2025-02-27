
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
        OR ss.ss_customer_sk IS NULL
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        CustomerSales c
    JOIN 
        customer_demographics cd ON c.c_customer_id = cd.cd_demo_sk
    WHERE 
        c.sales_rank <= 10
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_id,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(ca.ca_state, 'Unknown') AS state,
    TC.cd_gender,
    TC.cd_marital_status
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerAddresses ca ON tc.c_customer_id = ca.c_customer_id
WHERE 
    (tc.cd_credit_rating IS NOT NULL AND tc.cd_purchase_estimate > 1000)
UNION ALL
SELECT 
    'Total' AS c_first_name,
    NULL AS c_last_name,
    SUM(total_spent) AS total_spent,
    'N/A' AS city,
    'N/A' AS state,
    NULL AS cd_gender,
    NULL AS cd_marital_status
FROM 
    TopCustomers
ORDER BY 
    total_spent DESC;
