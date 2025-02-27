
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesData AS (
    SELECT 
        ss.s_customer_sk, 
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(ss.ss_ticket_number) AS total_sales_count
    FROM store_sales ss
    GROUP BY ss.s_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_buy_potential
)
SELECT 
    cd.gender,
    cd.cd_marital_status,
    cd.cd_buy_potential,
    COALESCE(SUM(rd.total_returned_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(sd.total_sales), 0) AS total_sales,
    COUNT(DISTINCT c.c_customer_sk) AS active_customers,
    AVG(sd.avg_sales_price) AS average_sales_price,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
FROM CustomerDemographics cd
LEFT JOIN CustomerReturns rd ON rd.c_customer_sk = cd.cd_demo_sk
LEFT JOIN SalesData sd ON sd.s_customer_sk = cd.cd_demo_sk
WHERE cd.customer_count > 5
GROUP BY cd.gender, cd.cd_marital_status, cd.cd_buy_potential
ORDER BY total_sales DESC, total_quantity_returned DESC
LIMIT 10;
