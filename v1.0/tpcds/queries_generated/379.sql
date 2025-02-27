
WITH SalesStats AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
),
CustomerFeedback AS (
    SELECT
        c.c_customer_sk,
        AVG(COALESCE(cr_return_quantity, 0)) AS avg_return_quantity,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM
        customer c
    LEFT JOIN
        web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    LEFT JOIN
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ss.total_sales) AS total_sales,
    AVG(cf.avg_return_quantity) AS avg_returns_per_customer
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    SalesStats ss ON ss.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN
    CustomerFeedback cf ON cf.c_customer_sk = c.c_customer_sk
WHERE
    ca.ca_state = 'CA' AND
    EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_store_sk = (
            SELECT MIN(s.s_store_sk)
            FROM store s
            WHERE s.s_state = ca.ca_state
        )
    )
GROUP BY
    ca.ca_city
ORDER BY
    total_sales DESC;
