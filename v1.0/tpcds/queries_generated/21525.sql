
WITH RankedSales AS (
    SELECT
        w.w_warehouse_id,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_by_profit
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY
        w.w_warehouse_id, ws.ws_item_sk
),
TopProducts AS (
    SELECT
        warehouse_id,
        ws_item_sk,
        total_quantity,
        total_profit
    FROM
        RankedSales
    WHERE
        rank_by_profit <= 5
),
CustomerReturns AS (
    SELECT
        sr.returning_customer_sk,
        COALESCE(SUM(sr.return_quantity), 0) AS total_returns,
        AVG(sr.return_amt) AS avg_return_amt,
        MAX(sr.returned_date_sk) AS last_return_date
    FROM
        store_returns sr
    GROUP BY
        sr.returning_customer_sk
),
ProfitAnalysis AS (
    SELECT
        c.c_customer_id,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender,
        SUM(COALESCE(tr.total_profit, 0)) AS total_profit,
        COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns,
        COALESCE(cr.avg_return_amt, 0) AS average_catalog_return,
        SUM(ta.total_quantity) AS total_products_returned
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        CustomerReturns cr ON cr.returning_customer_sk = c.c_customer_sk
    LEFT JOIN
        (SELECT DISTINCT ws_item_sk, total_profit FROM TopProducts) tr ON tr.ws_item_sk = ANY (
            SELECT DISTINCT ws_item_sk 
            FROM web_sales 
            WHERE ws_bill_customer_sk = c.c_customer_sk
        )
    LEFT JOIN
        (SELECT DISTINCT sr_customer_sk, SUM(sr_return_quantity) AS total_quantity
         FROM store_returns
         GROUP BY sr_customer_sk) ta ON ta.sr_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender
)
SELECT
    p.c_customer_id,
    p.gender,
    p.total_profit,
    p.average_catalog_return,
    p.total_products_returned,
    CASE 
        WHEN p.total_profit = 0 AND p.total_products_returned = 0 THEN 'No Activity'
        WHEN p.average_catalog_return > 50 THEN 'High Return'
        ELSE 'Normal Activity'
    END AS customer_activity_status
FROM
    ProfitAnalysis p
WHERE
    p.total_profit IS NOT NULL
ORDER BY
    p.total_profit DESC,
    p.average_catalog_return ASC
LIMIT 10 OFFSET 5;
