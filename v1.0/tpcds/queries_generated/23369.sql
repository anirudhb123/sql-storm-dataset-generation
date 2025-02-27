
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY ca.ca_zip) AS country_rank
    FROM customer_address ca
    WHERE ca.ca_country IS NOT NULL
),
LatestWebReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_returned
    FROM web_returns
    WHERE wr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY wr_returning_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COALESCE(MAX(lw.total_returned), 0) AS total_web_returns,
    COUNT(DISTINCT fa.ca_address_sk) AS unique_addresses,
    RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS web_sales_rank,
    CASE 
        WHEN SUM(ws.ws_net_paid) IS NULL THEN 'No Sales'
        ELSE 
            CASE 
                WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High Value Customer'
                WHEN SUM(ws.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
                ELSE 'Low Value Customer'
            END
    END AS customer_value_category
FROM web_sales ws
JOIN CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
LEFT JOIN LatestWebReturns lw ON cd.c_customer_sk = lw.wr_returning_customer_sk
LEFT JOIN FilteredAddresses fa ON cd.c_current_addr_sk = fa.ca_address_sk
WHERE cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
GROUP BY cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender
HAVING SUM(ws.ws_net_paid) IS NOT NULL 
   OR SUM(lw.total_returned) > 0
ORDER BY web_sales_rank, customer_value_category;
