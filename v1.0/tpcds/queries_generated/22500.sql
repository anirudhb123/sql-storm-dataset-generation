
WITH RankedSales AS (
    SELECT
        w.warehouse_id,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    JOIN
        warehouse w ON ws_warehouse_sk = w.warehouse_sk
    GROUP BY
        w.warehouse_id, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerMetrics AS (
    SELECT
        c.c_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_spent,
        CD.cd_gender AS gender,
        1.0 * COUNT(DISTINCT ws_order_number) / NULLIF(SUM(CASE WHEN cr.returning_customer_sk IS NOT NULL THEN 1 ELSE 0 END), 0) AS return_ratio
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    JOIN
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY
        c.c_customer_sk, CD.cd_gender
)
SELECT
    cm.c_customer_sk,
    cm.gender,
    cm.total_orders,
    cm.total_spent,
    COALESCE(rr.total_returns, 0) AS total_returns,
    COALESCE(rr.total_return_amount, 0) AS total_return_amount,
    MAX(rs.total_quantity) AS max_quantity_sold,
    CASE 
        WHEN cm.return_ratio IS NULL THEN 'No Sales'
        WHEN cm.return_ratio < 0.1 THEN 'Healthy'
        WHEN cm.return_ratio BETWEEN 0.1 AND 0.5 THEN 'Caution'
        ELSE 'High Risk'
    END AS risk_level
FROM
    CustomerMetrics cm
LEFT JOIN
    CustomerReturns rr ON cm.c_customer_sk = rr.sr_customer_sk
LEFT JOIN
    RankedSales rs ON rs.ws_item_sk IN (
        SELECT ws_item_sk FROM RankedSales WHERE rank <= 5
    )
GROUP BY
    cm.c_customer_sk, cm.gender, rr.total_returns, rr.total_return_amount
ORDER BY
    cm.total_spent DESC
FETCH FIRST 100 ROWS ONLY;
