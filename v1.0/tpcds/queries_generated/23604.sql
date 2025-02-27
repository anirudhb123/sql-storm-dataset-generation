
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_ticket_number, 
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn,
        COALESCE(sr_return_quantity, 0) AS return_qty,
        COALESCE(sr_return_amt, 0) AS return_amt,
        CASE 
            WHEN sr_return_quantity IS NULL THEN 'No Return'
            WHEN sr_return_quantity < 0 THEN 'Invalid Return'
            ELSE 'Valid Return' 
        END AS return_status
    FROM store_returns
),
FilteredReturns AS (
    SELECT 
        r.returned_date_sk,
        r.item_sk,
        SUM(r.return_qty) AS total_return_qty,
        SUM(r.return_amt) AS total_return_amt,
        r.return_status
    FROM RankedReturns r
    WHERE r.rn = 1
    GROUP BY r.returned_date_sk, r.item_sk, r.return_status
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_qty,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    fr.returned_date_sk,
    fr.item_sk,
    fr.total_return_qty,
    fr.total_return_amt,
    sd.total_sales_qty,
    sd.total_profit,
    CASE 
        WHEN fr.total_return_qty > sd.total_sales_qty THEN 'Returns Exceeded Sales'
        ELSE 'Normal'
    END AS return_vs_sales_status
FROM FilteredReturns fr
JOIN CustomerInfo ci ON ci.c_customer_sk IN (
    SELECT DISTINCT sr_customer_sk 
    FROM store_returns sr 
    WHERE sr_item_sk = fr.item_sk
)
LEFT JOIN SalesData sd ON fr.item_sk = sd.ws_item_sk
WHERE fr.return_status = 'Valid Return'
ORDER BY fr.returned_date_sk DESC, fr.total_return_amt DESC
LIMIT 100 OFFSET 0;
