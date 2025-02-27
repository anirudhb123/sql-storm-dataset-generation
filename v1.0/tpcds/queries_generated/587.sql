
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2450017 AND 2450652 -- Example date range
    GROUP BY
        ws_item_sk
),
HighValueCustomers AS (
    SELECT
        c_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_paid
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c_customer_sk
    HAVING
        SUM(ws_net_paid_inc_tax) > 1000 -- Filter for high-value customers
),
ItemReturns AS (
    SELECT
        cr_item_sk,
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_returned
    FROM
        catalog_returns
    WHERE
        cr_returned_date_sk BETWEEN 2450017 AND 2450652 -- Example date range
    GROUP BY
        cr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_sold,
    COALESCE(rs.total_sales, 0) AS total_revenue,
    COALESCE(ir.return_count, 0) AS total_returns,
    COALESCE(ir.total_returned, 0) AS total_returned_amt,
    COALESCE(hvc.c_customer_sk, 0) AS high_value_customer_id,
    CASE
        WHEN rs.total_sales > 0 THEN (COALESCE(ir.total_returned, 0) * 100.0 / rs.total_sales) 
        ELSE 0 
    END AS return_rate_percentage
FROM
    item i
LEFT JOIN
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
LEFT JOIN
    ItemReturns ir ON i.i_item_sk = ir.cr_item_sk
LEFT JOIN
    HighValueCustomers hvc ON hvc.total_paid IS NOT NULL
WHERE
    i.i_current_price > 50.00 -- Consider only high-priced items
ORDER BY
    return_rate_percentage DESC;
