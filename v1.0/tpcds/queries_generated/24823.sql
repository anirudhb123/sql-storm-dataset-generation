
WITH RECURSIVE customer_returns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr_order_number) AS unique_returns
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
), item_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        COUNT(DISTINCT ws_order_number) AS unique_sales
    FROM
        web_sales
    GROUP BY
        ws_item_sk
), sales_and_returns AS (
    SELECT
        is.ws_item_sk,
        is.total_sold,
        COALESCE(cr.total_return_quantity, 0) AS total_returned,
        COALESCE(cr.unique_returns, 0) AS total_unique_returns,
        (is.total_sold - COALESCE(cr.total_return_quantity, 0)) AS net_sales
    FROM
        item_sales is
    LEFT JOIN
        customer_returns cr ON cr.cr_returning_customer_sk = is.ws_item_sk
), price_summary AS (
    SELECT
        i.i_item_id,
        AVG(i.i_current_price) AS avg_price,
        MAX(i.i_current_price) AS max_price,
        MIN(i.i_current_price) AS min_price
    FROM
        item i
    JOIN
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss.ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        i.i_item_id
)
SELECT
    s.ws_order_number,
    s.ws_item_sk,
    s.total_sold,
    s.total_returned,
    s.net_sales AS final_net_sales,
    p.avg_price,
    p.max_price,
    p.min_price
FROM
    sales_and_returns s
JOIN
    price_summary p ON s.ws_item_sk = p.i_item_id
WHERE
    s.net_sales > (SELECT AVG(net_sales) FROM sales_and_returns WHERE total_sold > 0)
    OR s.total_unique_returns > 2
ORDER BY
    final_net_sales DESC
LIMIT 100;
