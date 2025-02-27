
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk

    UNION ALL

    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN SalesCTE s ON cs.cs_item_sk = s.ws_item_sk
    GROUP BY cs.cs_item_sk
),
Refunds AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
TotalSales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_quantity, 0) AS total_sold,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM SalesCTE s
    LEFT JOIN Refunds r ON s.ws_item_sk = r.sr_item_sk
),
IncomeBandRanges AS (
    SELECT 
        ib_income_band_sk,
        CONCAT(ib_lower_bound, ' - ', ib_upper_bound) AS income_range
    FROM income_band
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(inb.income_range, 'No Income Band') AS income_band,
    ts.total_sold,
    ts.total_sales,
    ts.total_returns,
    ts.total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY inb.income_band_sk ORDER BY ts.total_sales DESC) AS rank_by_sales
FROM customer c
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN IncomeBandRanges inb ON hd.hd_income_band_sk = inb.ib_income_band_sk
LEFT JOIN TotalSales ts ON ts.ws_item_sk = c.c_customer_sk
WHERE (c.c_birth_year IS NULL OR c.c_birth_year > 1970)
AND (ts.total_sold IS NOT NULL OR ts.total_sales > 0)
ORDER BY c.c_first_name, c.c_last_name;
