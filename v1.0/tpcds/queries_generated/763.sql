
WITH Revenue AS (
    SELECT
        ws.ws_order_number,
        ws.ws_payment_amt,
        ws.ws_ship_date_sk,
        d.d_date AS sale_date,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ship_date_sk) AS rank_order,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ship_date_sk DESC) AS recent_order_id
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
),
Refunds AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt_inc_tax) AS total_refunds
    FROM
        web_returns wr
    GROUP BY
        wr.wr_order_number
),
Sales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(ws_ship_date_sk) FROM web_sales) - 90
    GROUP BY
        ws.ws_order_number
)
SELECT
    COALESCE(s.ws_order_number, r.wr_order_number) AS order_number,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_refunds, 0) AS total_refunds,
    COALESCE(s.total_discount, 0) AS total_discount,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_refunds, 0) - COALESCE(s.total_discount, 0)) AS net_profit
FROM
    Sales s
FULL OUTER JOIN 
    Refunds r ON s.ws_order_number = r.wr_order_number
WHERE
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_refunds, 0) - COALESCE(s.total_discount, 0)) > 0
ORDER BY
    net_profit DESC
LIMIT 10;
