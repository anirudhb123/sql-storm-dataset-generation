
WITH RECURSIVE RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT cu.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer cu ON ca.ca_address_sk = cu.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
), SalesSummary AS (
    SELECT 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
), TopCities AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.customer_count,
        RANK() OVER (ORDER BY ad.customer_count DESC) AS city_rank
    FROM 
        AddressDetails ad
    WHERE 
        ad.customer_count IS NOT NULL
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    tc.ca_city,
    tc.customer_count,
    (SELECT COUNT(DISTINCT ws.ws_order_number)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = rc.c_customer_sk) AS order_count,
    (SELECT 
         CASE 
             WHEN SUM(ws.ws_net_paid) IS NULL THEN 'No Purchases'
             ELSE CAST(SUM(ws.ws_net_paid) AS CHAR)
         END
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = rc.c_customer_sk) AS net_paid_message,
    ss.total_sales,
    CASE 
        WHEN rc.rnk <= 10 THEN 'Top 10 Customer'
        WHEN tc.city_rank <= 5 THEN 'Top City'
        ELSE 'Regular'
    END AS customer_category
FROM 
    RankedCustomers rc 
LEFT JOIN 
    TopCities tc ON rc.rnk <= 10
CROSS JOIN 
    SalesSummary ss
WHERE 
    rc.total_spent > (SELECT AVG(total_spent) FROM RankedCustomers) OR rc.total_spent IS NULL
ORDER BY 
    rc.total_spent DESC NULLS LAST;
