
WITH RECURSIVE CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT
        c.c_customer_id,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_profit, 0) AS total_profit,
        CASE
            WHEN COALESCE(sd.total_sales, 0) > 0 THEN
                (COALESCE(cr.total_return_amt, 0) / COALESCE(sd.total_sales, 0)) * 100
            ELSE
                NULL
        END AS return_rate_percentage
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
FinalAnalysis AS (
    SELECT
        c_customer_id,
        total_return_quantity,
        total_return_amt,
        total_sales,
        total_profit,
        return_rate_percentage,
        RANK() OVER (ORDER BY return_rate_percentage DESC) AS return_rate_rank
    FROM CombinedData
)
SELECT
    c.c_customer_id,
    c.total_return_quantity,
    c.total_return_amt,
    c.total_sales,
    c.total_profit,
    c.return_rate_percentage,
    c.return_rate_rank,
    d.d_date AS sales_date,
    i.i_item_desc
FROM FinalAnalysis c
JOIN web_sales ws ON c.c_customer_id = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE d.d_year = 2023
AND c.return_rate_rank <= 10
ORDER BY c.return_rate_rank;
