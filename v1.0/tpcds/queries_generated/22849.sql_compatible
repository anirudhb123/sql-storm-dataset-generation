
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_current_cdemo_sk,
        COUNT(DISTINCT w.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ticket_number) AS store_orders,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_current_cdemo_sk
),
IncomeClassification AS (
    SELECT 
        h.hd_demo_sk,
        CASE 
            WHEN h.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN h.hd_income_band_sk BETWEEN 1 AND 5 THEN 'Low Income'
            WHEN h.hd_income_band_sk BETWEEN 6 AND 10 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_group
    FROM household_demographics h
),
WebReturnSummary AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.return_amt) AS total_returned_web_amt
    FROM web_returns wr
    WHERE wr.return_quantity > 0
    GROUP BY wr.refunded_customer_sk
),
StoreReturnSummary AS (
    SELECT 
        sr.refunded_customer_sk,
        SUM(sr.return_amt) AS total_returned_store_amt
    FROM store_returns sr
    WHERE sr.return_quantity > 0
    GROUP BY sr.refunded_customer_sk
)

SELECT 
    cs.c_customer_id,
    ic.income_group,
    cs.web_orders,
    cs.store_orders,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.total_store_sales, 0) AS total_store_sales,
    COALESCE(wrs.total_returned_web_amt, 0) AS total_returned_web_amt,
    COALESCE(srs.total_returned_store_amt, 0) AS total_returned_store_amt,
    (COALESCE(cs.total_web_sales, 0) - COALESCE(wrs.total_returned_web_amt, 0)) AS net_web_sales,
    (COALESCE(cs.total_store_sales, 0) - COALESCE(srs.total_returned_store_amt, 0)) AS net_store_sales
FROM CustomerStats cs
JOIN IncomeClassification ic ON cs.c_current_cdemo_sk = ic.hd_demo_sk
LEFT JOIN WebReturnSummary wrs ON cs.c_customer_id = wrs.refunded_customer_sk
LEFT JOIN StoreReturnSummary srs ON cs.c_customer_id = srs.refunded_customer_sk
WHERE 
    (cs.total_web_sales IS NOT NULL OR cs.total_store_sales IS NOT NULL)
    AND (wrs.total_returned_web_amt IS NULL OR wrs.total_returned_web_amt < 1000)
ORDER BY total_web_sales DESC, total_store_sales DESC
LIMIT 50;
