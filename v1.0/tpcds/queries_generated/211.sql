
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_band
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ship_date_sk, ws.ws_item_sk
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cr.total_return_amt,
    cr.return_count,
    sd.total_sales,
    sd.order_count,
    COALESCE(sd.total_sales, 0) - COALESCE(cr.total_return_amt, 0) AS net_sales,
    DENSE_RANK() OVER (PARTITION BY cd.purchase_band ORDER BY COALESCE(sd.total_sales, 0) - COALESCE(cr.total_return_amt, 0) DESC) AS sales_rank
FROM CustomerDemographics cd
LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN SalesData sd ON cr.sr_customer_sk = sd.ws_item_sk
WHERE cd.cd_gender IS NOT NULL AND cd.cd_marital_status IS NOT NULL
ORDER BY sales_rank, cd.c_customer_sk;
