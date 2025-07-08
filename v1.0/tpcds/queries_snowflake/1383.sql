
WITH CustomerReturnSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM
        customer c
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_store_returns,
        cr.total_web_returns,
        RANK() OVER (ORDER BY (cr.total_store_returns + cr.total_web_returns) DESC) AS customer_rank
    FROM
        CustomerReturnSummary cr
    JOIN
        customer c ON cr.c_customer_sk = c.c_customer_sk
    WHERE
        cr.total_store_returns + cr.total_web_returns > 0
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_store_returns,
    tc.total_web_returns,
    CASE 
        WHEN tc.customer_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_category
FROM
    TopCustomers tc
WHERE 
    EXISTS (
        SELECT 1
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_current_year = 'Y'
    ) 
AND NOT EXISTS (
        SELECT 1
        FROM promotion p 
        WHERE p.p_discount_active = 'Y'
        AND p.p_start_date_sk <= 20230101
        AND p.p_end_date_sk >= 20230101
        AND EXISTS (
            SELECT 1 
            FROM catalog_sales cs 
            WHERE cs.cs_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 20.00)
            AND cs.cs_order_number = (
                SELECT ws_order_number FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
            )
        )
    )
ORDER BY
    tc.total_store_returns DESC, tc.total_web_returns DESC;
