
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS SaleRank
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_qty,
        SUM(cr_return_amt) AS total_returned_amt
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
ReturnImpact AS (
    SELECT 
        cr.cr_returning_customer_sk,
        COALESCE(SUM(CASE WHEN rk.SaleRank = 1 THEN rk.ws_net_profit ELSE 0 END), 0) AS highest_net_profit,
        COALESCE(SUM(CASE WHEN cr.total_returned_qty > 0 THEN cr.total_returned_qty ELSE 0 END), 0) AS total_returns
    FROM CustomerReturns cr
    LEFT JOIN RankedSales rk ON cr.cr_returning_customer_sk = rk.ws_order_number
    GROUP BY cr.cr_returning_customer_sk
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ri.highest_net_profit,
    ri.total_returns,
    CASE 
        WHEN ri.total_returns > 0 THEN 'Customer has returns' 
        ELSE 'No returns' 
    END AS Return_Status
FROM ReturnImpact ri
JOIN customer c ON ri.cr_returning_customer_sk = c.c_customer_sk
WHERE ri.highest_net_profit > 1000
ORDER BY ri.highest_net_profit DESC;
