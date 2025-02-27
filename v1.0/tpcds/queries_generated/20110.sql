
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn,
        ws.ws_sales_price,
        ws.ws_net_profit,
        COALESCE(NULLIF(ws.ws_coupon_amt, 0), NULL) AS effective_coupon_amt
    FROM 
        web_sales ws
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_order_number = ss.ss_ticket_number
    WHERE 
        ws.ws_sales_price > 0 AND
        (ws.ws_net_profit IS NOT NULL OR ss.ss_net_profit IS NOT NULL)
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
ProfitSummary AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_net_profit) AS total_profit,
        SUM(CASE WHEN rs.rn = 1 THEN rs.effect_coupon_amt ELSE 0 END) AS total_discounted
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.sr_item_sk
    GROUP BY 
        rs.ws_order_number
),
SalesByShipMode AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        SUM(ps.total_profit) AS total_profit,
        AVG(ps.total_discounted) AS avg_discount
    FROM 
        ProfitSummary ps
    JOIN 
        web_sales ws ON ps.ws_order_number = ws.ws_order_number
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    'Ship Mode: ' || sm.sm_ship_mode_id AS ship_mode,
    order_count, 
    total_profit, 
    CASE 
        WHEN total_profit IS NULL THEN 'No Sales'
        WHEN avg_discount > 0 THEN 'Discounts Applied'
        ELSE 'No Discounts'
    END AS discount_status
FROM 
    SalesByShipMode sm
WHERE 
    total_profit > (SELECT AVG(total_profit) FROM SalesByShipMode)
ORDER BY 
    total_profit DESC
LIMIT 10;
