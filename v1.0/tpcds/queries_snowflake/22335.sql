
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_quantity) AS total_returned,
        AVG(sr_return_quantity) AS avg_returned
    FROM customer
    LEFT JOIN store_returns sr ON c_customer_sk = sr.sr_customer_sk
    LEFT JOIN customer_demographics cd ON c_customer_sk = cd.cd_demo_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name, cd_gender
),
SalesWithReasons AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        LISTAGG(DISTINCT r.r_reason_desc, ', ') WITHIN GROUP (ORDER BY r.r_reason_desc) AS reasons
    FROM web_sales ws
    LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_net_profit IS NOT NULL
    GROUP BY ws_bill_customer_sk, ws_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.return_count,
    cs.total_returned,
    cs.avg_returned,
    sw.total_profit,
    sw.reasons,
    COALESCE(r.return_rank, 0) AS recent_return_rank
FROM CustomerStats cs
LEFT JOIN SalesWithReasons sw ON cs.c_customer_sk = sw.ws_bill_customer_sk
LEFT JOIN RankedReturns r ON cs.c_customer_sk = r.sr_customer_sk AND r.return_rank = 1
WHERE 
    (cs.return_count > 3 OR cs.avg_returned > 2)
    AND (sw.total_profit < 0 OR sw.reasons IS NOT NULL)
ORDER BY cs.c_last_name DESC, cs.c_first_name ASC;
