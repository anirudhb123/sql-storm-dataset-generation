
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS total_orders_returned,
        cr_reason_sk
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk, cr_reason_sk
),
WebSalesSummary AS (
    SELECT
        ws_ship_customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS total_orders_sold,
        SUM(ws_net_profit) AS total_net_profit,
        MAX(ws_sales_price) AS max_sales_price
    FROM web_sales
    GROUP BY ws_ship_customer_sk
),
NegativeIncomeBand AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound < 0 OR ib_upper_bound < 0
),
JoinSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(ws.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ws.total_net_profit, 0) AS total_net_profit,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN WebSalesSummary ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN NegativeIncomeBand ib ON (
        -- Correlated subquery to check for matching income band
        (c.c_customer_sk IN (SELECT hd_demo_sk FROM household_demographics WHERE hd_income_band_sk = ib.ib_income_band_sk))
        OR (c.c_birth_year IS NOT NULL AND (c.c_birth_year % 2 = 0 OR (c.c_birth_year IS NULL AND ib.ib_lower_bound IS NOT NULL)))
    )
)
SELECT 
    js.c_customer_id,
    js.c_first_name,
    js.c_last_name,
    js.total_returned,
    js.total_quantity_sold,
    js.total_net_profit,
    js.ib_lower_bound,
    js.ib_upper_bound
FROM JoinSummary js
WHERE js.total_returned IS NOT NULL AND 
      (js.total_quantity_sold > 10 OR js.total_net_profit < 0)
ORDER BY 
    js.total_net_profit DESC NULLS LAST,
    js.total_returned ASC NULLS FIRST
LIMIT 100;
