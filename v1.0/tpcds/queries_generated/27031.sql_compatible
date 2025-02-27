
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        full_address,
        ca_city,
        ca_state
    FROM 
        RankedAddresses
    WHERE 
        address_rank <= 10
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        a.full_address IN (SELECT full_address FROM FilteredAddresses)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, a.full_address, d.d_year
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.full_address,
    cs.d_year,
    cs.total_orders,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerSummary cs
ORDER BY 
    cs.total_spent DESC, cs.c_last_name, cs.c_first_name;
