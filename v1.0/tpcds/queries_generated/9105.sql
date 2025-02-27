
WITH RankedReturns AS (
    SELECT
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS return_rank
    FROM store_returns sr
    JOIN customer c ON sr.customer_sk = c.customer_sk
    WHERE c.preferences IS NOT NULL
),
TopReturns AS (
    SELECT
        rr.returned_date_sk,
        rr.return_time_sk,
        rr.item_sk,
        rr.return_quantity,
        rr.return_amt,
        rr.customer_sk
    FROM RankedReturns rr
    WHERE rr.return_rank <= 5
),
SalesSummary AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(ws.order_number) AS total_orders
    FROM web_sales ws
    JOIN TopReturns tr ON ws.ship_customer_sk = tr.customer_sk
    GROUP BY ws.bill_customer_sk
),
CustomerDetails AS (
    SELECT
        c.customer_sk,
        c.first_name,
        c.last_name,
        cd.gender,
        cd.marital_status,
        SUM(ss.ext_sales_price) AS total_store_sales
    FROM customer c
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    JOIN store_sales ss ON ss.customer_sk = c.customer_sk
    GROUP BY c.customer_sk, c.first_name, c.last_name, cd.gender, cd.marital_status
)
SELECT
    sd.first_name,
    sd.last_name,
    sd.gender,
    sd.marital_status,
    ss.total_sales,
    ss.total_orders,
    sd.total_store_sales
FROM SalesSummary ss
JOIN CustomerDetails sd ON ss.bill_customer_sk = sd.customer_sk
ORDER BY ss.total_sales DESC, sd.last_name;
