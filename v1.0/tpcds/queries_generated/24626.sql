
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
),
TotalSales AS (
    SELECT 
        item.i_item_sk,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales
    FROM item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY item.i_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_marital_status = 'M' AND cd_cd_gender = 'F' THEN 'Married Female'
            WHEN cd.cd_marital_status = 'M' AND cd_cd_gender = 'M' THEN 'Married Male'
            ELSE 'Other'
        END AS marital_gender
    FROM customer_demographics cd
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        COALESCE(ts.i_item_sk, rs.sr_item_sk) AS item_sk,
        ts.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value
    FROM TotalSales ts
    FULL OUTER JOIN ReturnStats rs ON ts.i_item_sk = rs.sr_item_sk
)
SELECT 
    sas.item_sk,
    sas.total_sales,
    sas.total_returns,
    sas.total_return_value,
    CASE 
        WHEN sas.total_sales IS NULL THEN 'No Sales' 
        WHEN sas.total_return_value > sas.total_sales THEN 'Negative Profit'
        ELSE 'Normal'
    END AS sales_status,
    cd.marital_gender,
    RANK() OVER (ORDER BY sas.total_sales DESC) AS sales_rank
FROM SalesAndReturns sas
LEFT JOIN CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = sas.item_sk LIMIT 1)
WHERE sas.total_sales IS NULL OR sas.total_return_value IS NULL
ORDER BY sales_rank
LIMIT 100;
