
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_return_amt_inc_tax,
        COALESCE(sr_fee, 0) AS sr_fee,
        COALESCE(sr_return_ship_cost, 0) AS sr_return_ship_cost
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
AggregatedReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt_inc_tax) AS total_return_value
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(cr.total_return_value, 0)) AS total_return_value,
        SUM(sd.total_sold) AS total_sold,
        SUM(sd.total_revenue) AS total_revenue,
        COUNT(DISTINCT sd.order_count) AS distinct_orders,
        (SUM(COALESCE(cr.total_return_value, 0)) / NULLIF(SUM(sd.total_revenue), 0)) * 100 AS return_rate_percentage
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        SalesData sd ON cr.sr_item_sk = sd.ws_item_sk
    JOIN 
        customer c ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.total_return_value,
    fr.total_sold,
    fr.total_revenue,
    fr.distinct_orders,
    fr.return_rate_percentage
FROM 
    FinalReport fr
WHERE 
    fr.return_rate_percentage > 10 
    OR fr.total_return_value > 1000
ORDER BY 
    fr.return_rate_percentage DESC,
    fr.total_return_value DESC;
