
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
),
HighValueReturns AS (
    SELECT 
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        COALESCE(sr_return_amt_inc_tax, 0) - COALESCE(sr_fee, 0) AS net_return_value
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE WHEN cd.cd_credit_rating IS NULL OR cd.cd_credit_rating = 'Unknown' THEN 1 ELSE 0 END) AS unknown_credit_rating_count
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
WarehouseInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        COALESCE(SUM(hi.net_return_value), 0) AS total_high_value_returns
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND wr.wr_return_quantity > 0
    LEFT JOIN HighValueReturns hi ON hi.sr_ticket_number = ws.ws_order_number
    LEFT JOIN RankedSales rs ON rs.ws_order_number = ws.ws_order_number
    GROUP BY c.c_customer_id, cd.cd_gender
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.total_profit,
    f.total_return_loss,
    f.order_count,
    f.return_count,
    CASE 
        WHEN f.total_high_value_returns IS NULL THEN 'No returns'
        ELSE CAST(f.total_high_value_returns AS VARCHAR)
    END AS return_summary,
    CASE 
        WHEN f.total_return_loss < 0 THEN 'Profit'
        WHEN f.total_return_loss >= 0 AND f.order_count > 0 THEN 'Loss'
        ELSE 'Indeterminate'
    END AS overall_status
FROM FinalReport f
WHERE f.total_profit IS NOT NULL 
  AND (f.total_high_value_returns > 0 OR f.return_count > 0)
ORDER BY f.total_profit DESC, f.c_customer_id ASC
FETCH FIRST 100 ROWS ONLY;
