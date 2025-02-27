
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
    AND ws.ws_sales_price > 0
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(CASE WHEN ws.ws_net_profit IS NULL THEN 0 ELSE ws.ws_net_profit END) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cm.c_customer_sk,
        cm.cd_gender,
        cm.total_net_profit,
        RANK() OVER (ORDER BY cm.total_net_profit DESC) AS customer_rank
    FROM CustomerMetrics cm
),
ReturnStatistics AS (
    SELECT 
        CASE WHEN sr_item_sk IS NOT NULL THEN 'Store Return' ELSE 'Previous Type' END AS return_type,
        COALESCE(SUM(sr_return_quantity), 0) AS returned_quantity,
        COALESCE(SUM(sr_return_amt_inc_tax), 0.0) AS total_return_amount
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr ON sr.wr_item_sk = wr.wr_item_sk
    GROUP BY return_type
)
SELECT 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.total_net_profit,
    rs.returned_quantity,
    rs.total_return_amount,
    CASE 
        WHEN rs.total_return_amount < tc.total_net_profit THEN 'Profitable Catastrophe'
        ELSE 'Return Challenge'
    END AS return_analysis,
    STRING_AGG(DISTINCT CASE WHEN rank <= 3 THEN CONCAT('Order ', ws_order_number) END, ', ') AS top_orders
FROM TopCustomers tc
LEFT JOIN ReturnStatistics rs ON TRUE
LEFT JOIN RankedSales r ON r.ws_order_number = tc.c_customer_sk
WHERE tc.customer_rank <= 100 
AND (tc.total_net_profit - COALESCE(rs.total_return_amount, 0) > 0 OR rs.returned_quantity IS NULL)
GROUP BY tc.c_customer_sk, tc.cd_gender, tc.total_net_profit, rs.returned_quantity, rs.total_return_amount
ORDER BY tc.total_net_profit DESC;
