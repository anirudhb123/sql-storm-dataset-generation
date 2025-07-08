
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN ESTIMATE'
            WHEN cd.cd_purchase_estimate < 100 THEN 'LOW SPENDER'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 1000 THEN 'MEDIUM SPENDER'
            ELSE 'HIGH SPENDER'
        END AS spending_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ShippingStats AS (
    SELECT 
        ws_ship_mode_sk,
        sm_type,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws_ship_mode_sk, sm_type
    HAVING 
        SUM(ws_net_profit) > 0
),
FinalReport AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.spending_category,
        sr.total_returns,
        sr.total_returned_quantity,
        sr.total_returned_amount,
        ss.total_profit AS shipping_profit,
        ss.order_count AS total_orders,
        ROW_NUMBER() OVER (ORDER BY sr.total_returned_amount DESC) AS customer_rank
    FROM 
        CustomerInfo ci
    JOIN 
        RankedReturns sr ON ci.c_customer_sk = sr.sr_item_sk
    LEFT JOIN 
        ShippingStats ss ON ss.ws_ship_mode_sk = (SELECT MAX(ws_ship_mode_sk) FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
    WHERE 
        ci.cd_gender = 'M' AND 
        NOT EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_customer_sk = ci.c_customer_sk AND ss.ss_quantity < 0)
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    customer_rank <= 10
ORDER BY 
    total_returned_amount DESC
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
