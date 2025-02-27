
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr.return_quantity) AS total_returns,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(sr.sr_return_tax, 0)) AS total_return_tax,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(sr.sr_return_amt, 0)) DESC) AS return_rank
    FROM
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighReturnCustomers AS (
    SELECT
        *,
        CASE
            WHEN total_returns IS NULL THEN 'No Returns'
            WHEN total_returns > 10 THEN 'High Returns'
            ELSE 'Moderate Returns'
        END AS return_category
    FROM
        CustomerReturns
    WHERE
        total_returns IS NOT NULL
),
SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales_count
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT DISTINCT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT
    c.return_category,
    d.d_date,
    sd.total_sales,
    sd.total_sales_count
FROM
    HighReturnCustomers c
JOIN
    SalesData sd ON sd.ws_item_sk IN (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_item_desc LIKE '%special%'
    )
JOIN
    date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
WHERE
    c.return_rank = 1
ORDER BY
    c.return_category DESC, sd.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
