
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) AS email_domain
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.email_domain,
        sd.total_sales,
        sd.order_count,
        sd.avg_order_value
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
),
RankedData AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CombinedData 
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    email_domain,
    total_sales,
    order_count,
    avg_order_value,
    sales_rank
FROM 
    RankedData
WHERE 
    sales_rank <= 10 
ORDER BY 
    ca_state, total_sales DESC;
