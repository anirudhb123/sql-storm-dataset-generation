
WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(*) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd.cd_gender) AS genders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_net_profit,
        RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM SalesData sd
    WHERE sd.total_quantity_sold > 100
)
SELECT 
    cm.c_customer_sk,
    cm.total_orders,
    cm.total_profit,
    cm.avg_purchase_estimate,
    r.total_quantity_sold,
    r.total_net_profit,
    r.profit_rank
FROM CustomerMetrics cm
JOIN RankedSales r ON r.total_net_profit > cm.total_profit
WHERE cm.total_orders > (
    SELECT AVG(total_orders) FROM CustomerMetrics
)
ORDER BY cm.total_profit DESC
LIMIT 10;
