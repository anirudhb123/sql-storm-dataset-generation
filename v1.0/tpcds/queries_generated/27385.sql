
WITH Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        STRING_AGG(DISTINCT ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip, '; ') AS address_summary
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Address_Stats AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
Final_Output AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_orders,
        cs.total_spent,
        as.address_summary,
        ad.customer_count,
        ad.customer_names
    FROM 
        Customer_Stats cs
    JOIN 
        Address_Stats ad ON cs.address_summary LIKE '%' || ad.ca_city || '%' OR cs.address_summary LIKE '%' || ad.ca_state || '%'
)
SELECT 
    *
FROM 
    Final_Output
WHERE 
    total_spent > 1000
ORDER BY 
    total_spent DESC;
