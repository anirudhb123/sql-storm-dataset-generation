
WITH Customer_Totals AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Address_Totals AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk
),
Demographic_Summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(ct.total_sales) AS avg_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Customer_Totals ct ON c.c_customer_sk = ct.c_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    a.ca_address_sk,
    a.total_customers,
    a.customer_names,
    d.cd_gender,
    d.customer_count,
    d.avg_sales
FROM 
    Address_Totals a
JOIN 
    Demographic_Summary d ON 1=1
ORDER BY 
    a.total_customers DESC, d.customer_count DESC;
