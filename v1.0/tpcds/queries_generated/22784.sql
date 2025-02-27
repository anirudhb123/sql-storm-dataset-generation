
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL AND ws_net_profit IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN ws.net_paid > 100 THEN 1 ELSE 0 END) AS high_value_purchase_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
ReturnMetrics AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_returned_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
),
FinalReport AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_net_profit,
        ss.avg_sales_price,
        cs.total_orders,
        cs.high_value_purchase_count,
        COALESCE(rm.total_returns, 0) AS total_returns,
        COALESCE(rm.total_returned_amount, 0) AS total_returned_amount,
        CASE 
            WHEN cs.high_value_purchase_count > 5 THEN 'VIP' 
            ELSE 'Regular' 
        END AS customer_category
    FROM SalesSummary ss
    LEFT JOIN CustomerSales cs ON ss.ws_item_sk = cs.c_customer_sk
    LEFT JOIN ReturnMetrics rm ON ss.ws_item_sk = rm.cr_item_sk
    WHERE ss.total_sales > 10
),
FilteredFinal AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rn
    FROM FinalReport
    WHERE total_net_profit IS NOT NULL
)

SELECT 
    f.*,
    CASE 
        WHEN f.total_returns > 0 AND f.total_returned_amount / NULLIF(f.total_net_profit, 0) > 0.1 THEN 'High Return Rate' 
        ELSE 'Normal' 
    END AS return_rate_category
FROM FilteredFinal f
WHERE rn <= 100
ORDER BY total_net_profit DESC;
