
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr.returned_date_sk) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(sr.return_tax) AS total_return_tax
    FROM
        customer AS c
    LEFT JOIN store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ReturnRanked AS (
    SELECT
        cr.*,
        ROW_NUMBER() OVER (ORDER BY cr.total_returns DESC) AS return_rank
    FROM
        CustomerReturns AS cr
    WHERE
        cr.total_returns > 0
),
RecentSales AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS orders_count
    FROM
        web_sales AS ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day = 'Y')
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    rr.c_customer_sk,
    rr.c_first_name,
    rr.c_last_name,
    rr.total_returns,
    rr.total_return_amt,
    rr.total_return_tax,
    COALESCE(rs.total_net_profit, 0) AS total_net_profit,
    COALESCE(rs.orders_count, 0) AS orders_count,
    (
        SELECT COUNT(*) 
        FROM web_page AS wp
        WHERE wp.wp_customer_sk = rr.c_customer_sk
        AND wp.wp_creation_date_sk > (SELECT MIN(d_date_sk) FROM date_dim WHERE d_current_month = 'Y')
    ) AS page_visits,
    CASE 
        WHEN rr.total_returns > 5 THEN 'High Return'
        WHEN rr.total_returns BETWEEN 1 AND 5 THEN 'Moderate Return'
        ELSE 'No Returns'
    END AS return_category
FROM
    ReturnRanked AS rr
LEFT JOIN RecentSales AS rs ON rr.c_customer_sk = rs.ws_bill_customer_sk
WHERE
    rr.return_rank <= 10
ORDER BY
    rr.total_returns DESC, rr.c_last_name, rr.c_first_name;
