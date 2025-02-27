
WITH sales_summary AS (
    SELECT
        customer.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM
        web_sales
    JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    WHERE
        ws_sales_price > 100
    GROUP BY
        customer.c_customer_id
),
top_customers AS (
    SELECT
        c.c_customer_id,
        cs.order_count,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM
        sales_summary cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE
        cs.order_count > 1
),
invalid_returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_amt_inc_tax
    FROM
        web_returns wr
    WHERE
        wr.wr_return_amt IS NOT NULL
        AND wr.wr_return_amt < 0
),
shifted_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS net_profit
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk >= (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
              AND d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)
        )
    GROUP BY
        ws.ws_item_sk
)
SELECT
    tc.c_customer_id,
    tc.order_count,
    tc.total_spent,
    COALESCE(sr_returned_count.returned_count, 0) AS returned_count,
    COALESCE(ss.net_profit, 0) AS shifted_net_profit
FROM
    top_customers tc
LEFT OUTER JOIN (
    SELECT
        wr_refunded_customer_sk,
        COUNT(*) AS returned_count
    FROM
        invalid_returns
    GROUP BY
        wr_refunded_customer_sk
) sr_returned_count ON tc.c_customer_id = sr_returned_count.wr_refunded_customer_sk
LEFT JOIN (
    SELECT
        ss.ws_item_sk,
        SUM(ss.net_profit) AS net_profit
    FROM
        shifted_sales ss
    INNER JOIN item itm ON ss.ws_item_sk = itm.i_item_sk
    WHERE
        itm.i_current_price < (
          SELECT AVG(i_current_price) FROM item
          WHERE i_current_price IS NOT NULL
        )
    GROUP BY
        ss.ws_item_sk
) ss ON tc.total_spent > 0 AND ss.net_profit IS NOT NULL
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_spent DESC;
