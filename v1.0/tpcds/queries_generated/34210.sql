
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_country ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_country IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_country
), 
AddressData AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
), 
SalesByCity AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        COALESCE(SUM(sh.total_spent), 0) AS total_sales,
        COALESCE(SUM(ad.customer_count), 0) AS total_customers
    FROM 
        AddressData ad
    LEFT JOIN 
        (SELECT DISTINCT c_birth_country, c_customer_sk FROM SalesHierarchy) sh ON ad.ca_city = sh.c_birth_country
    GROUP BY 
        ad.ca_city, ad.ca_state
)

SELECT 
    s.ca_city, 
    s.ca_state, 
    s.total_sales, 
    s.total_customers, 
    s.total_sales / NULLIF(s.total_customers, 0) AS avg_spent_per_customer
FROM 
    SalesByCity s
WHERE 
    s.total_sales > 10000 
    AND (s.total_customers = 0 OR s.total_customers >= 10)
UNION ALL
SELECT 
    'Total' AS ca_city, 
    NULL AS ca_state, 
    SUM(s.total_sales) AS total_sales, 
    SUM(s.total_customers) AS total_customers,
    SUM(s.total_sales) / NULLIF(SUM(s.total_customers), 0) AS avg_spent_per_customer
FROM 
    SalesByCity s;
