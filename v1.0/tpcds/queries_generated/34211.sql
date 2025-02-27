
WITH RECURSIVE SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_ticket_number) OVER (PARTITION BY c.c_customer_sk) AS unique_transactions,
        DENSE_RANK() OVER (ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_sales_price) DESC) AS rn
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk
)
, AddressWithDemographics AS (
    SELECT 
        a.ca_address_sk,
        a.ca_city,
        cd.cd_gender,
        SUM(ss.ss_sales_price) AS address_sales
    FROM customer_address a
    JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY a.ca_address_sk, a.ca_city, cd.cd_gender
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales,
    tc.total_transactions,
    a.ca_city,
    a.cd_gender,
    a.address_sales,
    (COALESCE(SUM(a.address_sales), 0) - COALESCE(tc.total_sales, 0)) AS sales_difference
FROM TopCustomers tc
LEFT JOIN AddressWithDemographics a ON tc.c_customer_sk = a.ca_address_sk
WHERE tc.rn <= 10 
ORDER BY sales_difference DESC;
