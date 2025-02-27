
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS row_num
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
), HighSales AS (
    SELECT
        ws_item_sk,
        total_sales
    FROM
        SalesCTE
    WHERE
        row_num <= 10
), CustomerInfo AS (
    SELECT
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        id_income_band_sk,
        CASE
            WHEN cd_purchase_estimate IS NULL THEN 'Unknown'
            ELSE cd_credit_rating
        END AS credit_info
    FROM
        customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
), ItemCatalog AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_current_price,
        ROW_NUMBER() OVER (ORDER BY i_current_price) AS price_rank
    FROM
        item
    WHERE
        i_rec_end_date >= CURRENT_DATE
), JoinResults AS (
    SELECT
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        hi.total_sales,
        ic.i_item_desc,
        ic.i_current_price
    FROM
        CustomerInfo ci
    JOIN HighSales hi ON ci.c_customer_sk = hi.ws_item_sk
    JOIN ItemCatalog ic ON hi.ws_item_sk = ic.i_item_sk
)
SELECT
    jr.c_customer_sk,
    jr.cd_gender,
    jr.cd_marital_status,
    COALESCE(jr.total_sales, 0) AS total_sales,
    jr.i_item_desc,
    jr.i_current_price,
    CASE
        WHEN jr.total_sales > 1000 THEN 'High Value'
        WHEN jr.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM
    JoinResults jr
ORDER BY
    customer_value_segment DESC,
    jr.total_sales DESC;
