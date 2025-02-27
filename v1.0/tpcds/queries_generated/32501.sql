
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM store_returns
    GROUP BY sr_returning_customer_sk
    HAVING SUM(sr_return_quantity) > 0
),
ActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is.total_sold,
        is.total_revenue,
        is.order_count,
        RANK() OVER (ORDER BY is.total_revenue DESC) AS revenue_rank
    FROM item i
    JOIN ItemSales is ON i.i_item_sk = is.ws_item_sk
),
FilteredReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(cr.returning_customer_sk) AS return_count,
        SUM(cr.return_quantity) AS total_returned
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
    HAVING SUM(cr.return_quantity) IS NOT NULL
),
ShippingMethods AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
)
SELECT 
    ac.c_customer_sk,
    ac.c_first_name,
    ac.c_last_name,
    ac.cd_gender,
    ac.cd_marital_status,
    cr.total_returned_quantity,
    cr.total_returned_amount,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sold,
    ti.total_revenue,
    sm.order_count AS shipping_method_count,
    CASE 
        WHEN cr.total_returned_quantity IS NULL THEN 'No Returns'
        WHEN cr.return_count = 0 THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM ActiveCustomers ac
LEFT JOIN CustomerReturns cr ON ac.c_customer_sk = cr.returning_customer_sk
LEFT JOIN TopItems ti ON ti.revenue_rank <= 10
JOIN ShippingMethods sm ON sm.order_count > 0
ORDER BY ac.c_customer_sk, ti.total_revenue DESC;
