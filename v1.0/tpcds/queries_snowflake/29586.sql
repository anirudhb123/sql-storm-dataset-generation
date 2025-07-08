
WITH ProcessedWebSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_returned_amount,
        SUM(ws.ws_net_paid) AS total_paid_amount,
        CASE
            WHEN SUM(ws.ws_net_paid) > 0 THEN
                ROUND((SUM(wr.wr_return_amt) / SUM(ws.ws_net_paid)) * 100, 2)
            ELSE
                0
        END AS return_rate_percentage
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN
        web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY
        ws.ws_order_number, ws.ws_item_sk, ws.ws_net_paid, c.c_first_name, c.c_last_name
)
SELECT
    customer_full_name,
    COUNT(ws_order_number) AS total_orders,
    SUM(total_paid_amount) AS total_paid,
    SUM(total_returned_amount) AS total_returns,
    AVG(return_rate_percentage) AS average_return_rate
FROM
    ProcessedWebSales
GROUP BY
    customer_full_name
ORDER BY
    total_paid DESC
LIMIT 10;
