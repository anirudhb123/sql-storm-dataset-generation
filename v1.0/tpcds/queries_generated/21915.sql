
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
ProfitableItems AS (
    SELECT
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        r.total_sales - (i.i_wholesale_cost * r.total_quantity) AS profit_margin
    FROM
        RankedSales r
    JOIN
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE
        r.sales_rank = 1
        AND r.total_sales > 1000 -- Arbitrary threshold for filtering
),
CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        (CASE 
            WHEN COUNT(DISTINCT sr_ticket_number) > 0 THEN ROUND(SUM(sr_return_amt) / COUNT(DISTINCT sr_ticket_number), 2) 
            ELSE 0 
        END) AS avg_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
TopReturningCustomers AS (
    SELECT
        c.c_customer_id,
        cr.return_count,
        cr.total_return_amt,
        cr.avg_return_amount
    FROM
        CustomerReturns cr
    JOIN
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE
        cr.return_count > 5
),
WarehousePerformance AS (
    SELECT
        w.w_warehouse_id,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
    FROM
        warehouse w
    JOIN
        web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_id
)
SELECT
    COALESCE(trc.c_customer_id, 'No Returns') AS customer_id,
    tp.ws_item_sk,
    tp.total_quantity,
    tp.total_sales,
    COALESCE(top_r.return_count, 0) AS total_returns,
    COALESCE(top_r.avg_return_amount, 0.00) AS avg_return,
    wp.total_orders,
    wp.distinct_items
FROM
    ProfitableItems tp
LEFT JOIN
    TopReturningCustomers top_r ON tp.ws_item_sk IN (SELECT DISTINCT wr_item_sk FROM web_returns) AND top_r.return_count > 0
LEFT JOIN
    WarehousePerformance wp ON wp.total_orders > 0
WHERE
    (tp.profit_margin > 0 OR tp.total_sales IS NULL)
ORDER BY
    total_sales DESC NULLS LAST;
