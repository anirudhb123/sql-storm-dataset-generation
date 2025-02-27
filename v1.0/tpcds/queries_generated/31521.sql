
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 
           ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_item_sk) AS rn
    FROM item
    WHERE i_current_price IS NOT NULL
),
MaxReturns AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        sr_item_sk
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerIncome AS (
    SELECT 
        cd_demo_sk,
        MAX(hd_income_band_sk) AS max_income_band,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    GROUP BY cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk > 0
    GROUP BY ws_item_sk
)

SELECT 
    ih.i_item_id,
    ih.i_item_desc,
    ih.i_current_price,
    COALESCE(mr.total_returns, 0) AS total_returns,
    COALESCE(sd.total_sales_price, 0) AS total_sales_price,
    ci.customer_count,
    MAX(ci.max_income_band) AS income_band
FROM ItemHierarchy ih
LEFT JOIN MaxReturns mr ON ih.i_item_sk = mr.sr_item_sk
LEFT JOIN SalesData sd ON ih.i_item_sk = sd.ws_item_sk
JOIN CustomerIncome ci ON ci.max_income_band IS NOT NULL
GROUP BY ih.i_item_id, ih.i_item_desc, ih.i_current_price, ci.customer_count
HAVING MAX(ih.rn) > 1
ORDER BY total_sales_price DESC, total_returns DESC
LIMIT 10;
