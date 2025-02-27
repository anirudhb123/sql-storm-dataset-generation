
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY sr_item_sk
),
CustomerSegment AS (
    SELECT 
        c_customer_sk,
        CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE ib_income_band_sk 
        END AS income_segment,
        COUNT(*) AS customer_count
    FROM customer
    LEFT JOIN household_demographics ON hd_demo_sk = c_current_hdemo_sk
    LEFT JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY c_customer_sk, ib_income_band_sk
)
SELECT 
    i.i_item_id,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(c.customer_count, 0) AS customer_count,
    s.rank
FROM item i
LEFT JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN RecentReturns r ON i.i_item_sk = r.sr_item_sk
LEFT JOIN CustomerSegment c ON i.i_item_sk = c.c_customer_sk
WHERE (s.total_sales > 1000 OR r.total_returns > 5)
    AND i.i_current_price IS NOT NULL
ORDER BY total_sales DESC, total_returns ASC;
