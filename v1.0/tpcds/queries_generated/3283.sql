
WITH CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns_count
    FROM web_returns
    WHERE wr_returned_date_sk IS NOT NULL
    GROUP BY wr_returned_date_sk, wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
)
SELECT 
    ca.city,
    ad.cd_gender,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    cd_purchase_estimate,
    (WINDOW_FUNCTIONS.total_sales_price / NULLIF(WINDOW_FUNCTIONS.total_sales_count, 0)) AS avg_sales_price
FROM customer_address ca
LEFT JOIN CustomerReturns cr ON ca.ca_address_sk = cr.wr_returning_customer_sk
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN CustomerDemographics ad ON c.c_current_cdemo_sk = ad.cd_demo_sk
JOIN (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS total_sales_count,
        DENSE_RANK() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk, ws_ship_date_sk
) WINDOW_FUNCTIONS ON c.c_customer_sk = WINDOW_FUNCTIONS.ws_bill_customer_sk
WHERE ad.cd_gender = 'F' 
AND cr.total_return_amount > 100 
OR (cr.total_return_quantity IS NULL AND ad.cd_marital_status = 'M')
ORDER BY ca.city, total_return_amount DESC
LIMIT 100;
