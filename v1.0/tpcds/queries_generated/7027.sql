
WITH SalesData AS (
    SELECT 
        ws_bil_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer_demographics
),
TopCustomers AS (
    SELECT 
        sd.ws_bill_customer_sk,
        sd.total_quantity,
        sd.total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM SalesData sd
    JOIN customer c ON sd.ws_bil_customer_sk = c.c_customer_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ORDER BY sd.total_profit DESC
    LIMIT 10
)
SELECT 
    tc.ws_bill_customer_sk,
    tc.total_quantity,
    tc.total_profit,
    tc.cd_gender,
    tc.cd_marital_status,
    CASE 
        WHEN tc.cd_purchase_estimate BETWEEN 0 AND 500 THEN 'Low'
        WHEN tc.cd_purchase_estimate BETWEEN 501 AND 2000 THEN 'Medium'
        ELSE 'High'
    END AS purchase_estimate_band
FROM TopCustomers tc;
