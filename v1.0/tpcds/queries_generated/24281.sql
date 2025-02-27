
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
ItemSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_qty,
        SUM(ws_net_paid) AS total_sales_amt
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerDemographic AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
NullHandling AS (
    SELECT
        id,
        CASE 
            WHEN income_band_sk IS NULL THEN 'Unknown'
            ELSE CONCAT('Income Band: ', income_band_sk)
        END AS income_handled
    FROM (
        SELECT DISTINCT 
            c.c_customer_sk AS id,
            cd.cd_purchase_estimate,
            cd.cd_credit_rating,
            COALESCE(hd.hd_income_band_sk, NULL) AS income_band_sk
        FROM customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    ) AS subquery
),
FinalResults AS (
    SELECT
        a.c_customer_sk,
        a.c_first_name,
        a.c_last_name,
        a.income_handled,
        COALESCE(b.total_sales_qty, 0) AS total_sales_qty,
        COALESCE(b.total_sales_amt, 0.00) AS total_sales_amt,
        c.sr_return_quantity,
        c.sr_return_amt
    FROM CustomerDemographic a
    LEFT JOIN ItemSales b ON a.c_customer_sk = b.ws_item_sk
    LEFT JOIN (
        SELECT 
            rr.sr_item_sk,
            SUM(rr.sr_return_quantity) AS sr_return_quantity,
            SUM(rr.sr_return_amt) AS sr_return_amt
        FROM RankedReturns rr
        WHERE rr.rn <= 5
        GROUP BY rr.sr_item_sk
    ) c ON b.ws_item_sk = c.sr_item_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.income_handled,
    f.total_sales_qty,
    f.total_sales_amt,
    CASE 
        WHEN f.total_sales_amt = 0 THEN 'No Sales' 
        ELSE 'Sales Made' 
    END AS sales_status,
    ROW_NUMBER() OVER (ORDER BY f.total_sales_amt DESC) AS rank
FROM FinalResults f
WHERE f.total_sales_amt IS NOT NULL
ORDER BY f.total_sales_amt DESC, f.c_last_name ASC;
