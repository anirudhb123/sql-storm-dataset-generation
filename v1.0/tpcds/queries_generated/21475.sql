
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sales_price IS NOT NULL
        AND ws_sales_price > 0
),
cumulative_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS cumulative_total
    FROM
        ranked_sales
    WHERE
        rn = 1
),
item_demographics AS (
    SELECT
        i.i_item_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'Unknown') AS credit_rating,
        hd.hd_income_band_sk
    FROM
        item i
    LEFT JOIN customer_demographics cd ON i.i_item_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
returns_summary AS (
    SELECT
        cr_item_sk,
        COUNT(*) as return_count,
        SUM(cr_return_amount) AS total_return_amt
    FROM
        catalog_returns
    GROUP BY
        cr_item_sk
),
sales_with_returns AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales_amt,
        COALESCE(r.return_count, 0) AS total_return_count,
        COALESCE(r.total_return_amt, 0.00) AS total_return_amt
    FROM
        web_sales ws
    LEFT JOIN returns_summary r ON ws.ws_item_sk = r.cr_item_sk
    GROUP BY
        ws.ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    d.cumulative_total,
    s.total_sales_amt,
    s.total_return_count,
    s.total_return_amt,
    id.cd_gender,
    id.credit_rating,
    CASE 
        WHEN s.total_sales_amt > 10000 THEN 'High'
        WHEN s.total_sales_amt BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    item i
JOIN cumulative_sales d ON i.i_item_sk = d.ws_item_sk
JOIN sales_with_returns s ON i.i_item_sk = s.ws_item_sk
JOIN item_demographics id ON i.i_item_sk = id.i_item_sk
WHERE
    (s.total_return_count = 0 OR (s.total_return_amt > 100 AND id.cd_gender = 'F'))
    AND s.total_sales_amt IS NOT NULL
ORDER BY
    d.cumulative_total DESC, s.total_sales_amt ASC
LIMIT 50 OFFSET 10
```
