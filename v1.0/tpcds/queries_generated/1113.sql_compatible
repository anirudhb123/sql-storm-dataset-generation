
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
CustomerReturns AS (
    SELECT
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returned_amount,
        COUNT(wr.wr_order_number) AS total_returns
    FROM
        web_returns wr
    WHERE
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY
        wr.wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT
        cr.wr_returning_customer_sk
    FROM
        CustomerReturns cr
    WHERE
        cr.total_returned_amount > (
            SELECT AVG(total_returned_amount) FROM CustomerReturns
        )
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ws.web_site_id,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid) AS total_sales
FROM
    customer c
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    RankedSales rs ON ws.ws_order_number = rs.ws_order_number
WHERE
    c.c_customer_sk IN (SELECT wr_returning_customer_sk FROM HighReturnCustomers)
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name, ws.web_site_id
HAVING
    SUM(ws.ws_net_paid) > 1000
ORDER BY
    total_sales DESC;
