
WITH sales_summary AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND dd.d_moy IN (6, 7)  -- June and July
    GROUP BY
        ws.web_site_id
),
top_web_sites AS (
    SELECT
        web_site_id
    FROM
        sales_summary
    WHERE
        sales_rank <= 5
),
customer_returns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(wr_order_number) AS return_count
    FROM
        web_returns
    WHERE
        wr_returned_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_moy IN (6, 7)
        )
    GROUP BY
        wr_returning_customer_sk
)
SELECT
    ca.ca_address_id,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    (SUM(ws.ws_net_paid_inc_tax) - COALESCE(SUM(cr.cr_return_amount), 0)) AS net_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COUNT(DISTINCT cr.cr_order_number) AS return_count
FROM
    web_sales ws
LEFT JOIN
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    catalog_returns cr ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
WHERE
    c.c_customer_id IN (
        SELECT c.c_customer_id
        FROM customer c
        WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = 'San Francisco')
    )
    AND ws.ws_web_site_sk IN (SELECT web_site_sk FROM top_web_sites)
GROUP BY
    ca.ca_address_id,
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY
    net_sales DESC;
