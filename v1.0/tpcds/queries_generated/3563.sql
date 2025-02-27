
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank 
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        cs.total_web_sales,
        cs.web_order_count 
    FROM 
        (SELECT 
            c_customer_id AS customer_id,
            c_first_name AS first_name,
            c_last_name AS last_name,
            ROW_NUMBER() OVER (ORDER BY total_web_sales DESC) AS rn
         FROM 
            CustomerSales cs) c
    WHERE 
        rn <= 10
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tc.customer_id,
    tc.first_name,
    tc.last_name,
    tc.total_web_sales,
    tc.web_order_count,
    COALESCE(ca.ca_city, 'N/A') AS city,
    COALESCE(ca.ca_state, 'N/A') AS state,
    COALESCE(ca.ca_country, 'N/A') AS country
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerAddresses ca ON tc.customer_id = ca.c_customer_id
WHERE 
    ca.ca_state IS NOT NULL OR tc.total_web_sales > 5000
ORDER BY 
    tc.total_web_sales DESC, tc.web_order_count DESC;
