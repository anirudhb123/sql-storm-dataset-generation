
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_email_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_email_address IS NOT NULL
),
AddressSummary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        LISTAGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
),
RecentPurchases AS (
    SELECT 
        cs.cs_bill_customer_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_sales_price) AS total_sales
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CAST('2002-10-01' AS DATE) - INTERVAL '30 DAY')
    GROUP BY 
        cs.cs_bill_customer_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.c_email_address,
    asum.ca_city,
    asum.customer_count,
    rp.total_quantity,
    rp.total_sales
FROM 
    RankedCustomers rc
LEFT JOIN 
    AddressSummary asum ON rc.c_customer_sk = asum.ca_address_sk
LEFT JOIN 
    RecentPurchases rp ON rc.c_customer_sk = rp.cs_bill_customer_sk
WHERE 
    rc.rank <= 5
ORDER BY 
    rc.cd_gender, rc.full_name;
