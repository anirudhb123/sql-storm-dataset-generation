
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_qty) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_quantity,
        cr.total_return_amt_inc_tax
    FROM
        customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE
        cr.total_returns > (
            SELECT AVG(total_returns) FROM CustomerReturns
        )
),
SalesData AS (
    SELECT
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS total_sales_count
    FROM
        web_sales
    GROUP BY
        ws_ship_date_sk, ws_item_sk
),
DailySales AS (
    SELECT
        dd.d_date,
        SUM(sd.total_sales_price) AS daily_total_sales,
        COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
    FROM
        date_dim dd
    LEFT JOIN SalesData sd ON dd.d_date_sk = sd.ws_ship_date_sk
    GROUP BY
        dd.d_date
)
SELECT
    hwc.c_customer_id,
    hwc.c_first_name,
    hwc.c_last_name,
    ds.d_date,
    ds.daily_total_sales,
    ds.unique_items_sold,
    COALESCE(ds.daily_total_sales, 0) - COALESCE((SELECT AVG(daily_total_sales) FROM DailySales), 0) AS sales_variation,
    CASE 
        WHEN ds.daily_total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Active' 
    END AS sales_status
FROM
    HighReturnCustomers hwc
CROSS JOIN DailySales ds
ORDER BY
    hwc.c_customer_id,
    ds.d_date DESC;
