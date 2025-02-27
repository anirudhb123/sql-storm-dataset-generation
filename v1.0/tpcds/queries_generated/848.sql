
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
TopSellingItems AS (
    SELECT
        i.i_item_id,
        R.total_sales
    FROM
        RankedSales R
    JOIN
        item i ON R.ws_item_sk = i.i_item_sk
    WHERE
        R.sales_rank = 1
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM
        store_returns
    WHERE
        sr_return_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        sr_customer_sk
)
SELECT
    c.c_customer_id,
    COALESCE(CR.total_return_amt, 0) AS total_return_amt,
    COALESCE(CR.total_returns, 0) AS total_returns,
    T.total_sales AS top_sales
FROM
    customer c
LEFT JOIN
    CustomerReturns CR ON c.c_customer_sk = CR.sr_customer_sk
LEFT JOIN
    TopSellingItems T ON CR.total_returns > 0
WHERE
    (c.c_birth_year < 1980 OR c.c_preferred_cust_flag = 'Y')
    AND (CR.total_return_amt IS NULL OR CR.total_return_amt < 100)
ORDER BY
    total_return_amt DESC, top_sales DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
