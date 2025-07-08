
WITH RECURSIVE AddressCTE AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
    UNION ALL
    SELECT 
        ca_address_sk,
        ca_address_id,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        rn + 1
    FROM 
        AddressCTE
    WHERE 
        rn < 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk
),
TopCustomers AS (
    SELECT 
        cs.c_current_cdemo_sk,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerSales
        )
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    ac.ca_address_id,
    dc.cd_gender,
    dc.cd_marital_status,
    dc.income_band,
    tc.total_spent,
    CASE
        WHEN tc.rank <= 5 THEN 'Top Customer'
        WHEN tc.rank IS NULL THEN 'No Sales'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    AddressCTE ac
LEFT JOIN 
    TopCustomers tc ON ac.ca_address_sk = tc.c_current_cdemo_sk
LEFT JOIN 
    Demographics dc ON tc.c_current_cdemo_sk = dc.cd_demo_sk
WHERE 
    ac.ca_zip IS NOT NULL
    AND ac.ca_state IN ('CA', 'NY')
    AND (dc.cd_gender IS NOT NULL OR dc.cd_marital_status IS NOT NULL)
ORDER BY 
    ac.ca_city, 
    total_spent DESC
LIMIT 100 OFFSET 10;
