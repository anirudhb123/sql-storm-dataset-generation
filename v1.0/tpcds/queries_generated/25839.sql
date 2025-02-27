
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as GenderRank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM RankedCustomers c
    WHERE c.GenderRank <= 5
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.c_email_address
    FROM customer_address ca
    JOIN TopCustomers tc ON tc.c_customer_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS TotalSpent,
        COUNT(ss.ss_ticket_number) AS TotalPurchases
    FROM store_sales ss
    WHERE ss.ss_customer_sk IN (SELECT DISTINCT c_customer_sk FROM TopCustomers)
    GROUP BY ss.ss_customer_sk
)
SELECT 
    ca.c_first_name,
    ca.c_last_name,
    ca.c_email_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COALESCE(sd.TotalSpent, 0) AS TotalSpent,
    COALESCE(sd.TotalPurchases, 0) AS TotalPurchases
FROM CustomerAddress ca
LEFT JOIN SalesData sd ON ca.c_customer_sk = sd.ss_customer_sk
ORDER BY ca.ca_city, TotalSpent DESC;
