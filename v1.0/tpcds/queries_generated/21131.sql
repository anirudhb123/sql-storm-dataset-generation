
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_returned_date_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(*) DESC) AS rn
    FROM store_returns
    GROUP BY sr_item_sk, sr_returned_date_sk
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
SalesAndReturns AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_sold,
        ts.total_sales,
        ts.avg_net_profit,
        COALESCE(rr.return_count, 0) AS total_return_count,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt
    FROM TotalSales ts
    LEFT JOIN RankedReturns rr ON ts.ws_item_sk = rr.sr_item_sk AND rr.rn = 1
),
FinalOutput AS (
    SELECT 
        sar.ws_item_sk,
        sar.total_sold,
        sar.total_sales,
        sar.total_return_count,
        sar.total_return_amt,
        ROUND(sar.total_sales / NULLIF(sar.total_sold, 0), 2) AS sales_per_unit,
        CASE 
            WHEN sar.total_return_count > 0 THEN ROUND((sar.total_return_amt / sar.total_sales) * 100, 2)
            ELSE NULL 
        END AS return_rate,
        CASE 
            WHEN sar.avg_net_profit < 0 THEN 'Loss Leader'
            WHEN sar.avg_net_profit IS NULL THEN 'No Profit Data'
            ELSE 'Profit'
        END AS profit_status
    FROM SalesAndReturns sar
    WHERE sar.total_sales > 1000 OR sar.total_return_count > 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ci.ws_item_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN FinalOutput fo ON ws.ws_item_sk = fo.ws_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    fo.total_sold,
    fo.total_sales,
    fo.total_return_count,
    fo.return_rate,
    fo.profit_status
FROM CustomerInfo ci
JOIN FinalOutput fo ON ci.ws_item_sk = fo.ws_item_sk
ORDER BY fo.total_sales DESC, fo.return_rate DESC;
