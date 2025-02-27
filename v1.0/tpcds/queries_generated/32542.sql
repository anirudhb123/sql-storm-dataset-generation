
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_order_number, ws_item_sk
    HAVING
        SUM(ws_net_paid) > 100
),
HighValueReturns AS (
    SELECT
        wr_order_number,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM
        web_returns
    GROUP BY
        wr_order_number
    HAVING
        SUM(wr_return_amt_inc_tax) > 50
),
JoinedSales AS (
    SELECT
        c.c_customer_id,
        s.ss_sold_date_sk,
        ss_item_sk,
        COALESCE(ws.total_net_paid, 0) AS total_sales,
        COALESCE(hr.total_return_amt_inc_tax, 0) AS total_returns
    FROM
        store_sales s
    LEFT JOIN SalesCTE ws ON s.ss_order_number = ws.ws_order_number
    LEFT JOIN HighValueReturns hr ON s.ss_order_number = hr.wr_order_number
    JOIN customer c ON c.c_customer_sk = s.ss_customer_sk
    WHERE
        s.ss_sold_date_sk >= 20230101
)
SELECT
    ja.c_customer_id,
    SUM(ja.total_sales) AS grand_total_sales,
    SUM(ja.total_returns) AS grand_total_returns,
    (SUM(ja.total_sales) - SUM(ja.total_returns)) AS net_revenue,
    CASE
        WHEN SUM(ja.total_sales) = 0 THEN 0
        ELSE (SUM(ja.total_returns) / SUM(ja.total_sales)) * 100
    END AS return_percentage
FROM
    JoinedSales ja
GROUP BY
    ja.c_customer_id
ORDER BY
    grand_total_sales DESC
LIMIT 10;
