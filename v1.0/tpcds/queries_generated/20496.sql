
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE c.c_birth_year BETWEEN 1970 AND 1995
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity IS NOT NULL
    GROUP BY cr.cr_item_sk
),
CombinedStats AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.rank_sales,
        rs.total_net_profit,
        COALESCE(ic.total_quantity_on_hand, 0) AS stock_on_hand,
        COALESCE(fr.total_returns, 0) AS returns_count,
        CASE 
            WHEN COALESCE(ic.total_quantity_on_hand, 0) = 0 THEN 'Out of Stock'
            WHEN COALESCE(fr.total_returns, 0) > 0 THEN 'Returns Present'
            ELSE 'In Stock'
        END AS stock_status
    FROM RankedSales rs
    LEFT JOIN InventoryCheck ic ON rs.ws_item_sk = ic.inv_item_sk
    LEFT JOIN FilteredReturns fr ON rs.ws_item_sk = fr.cr_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_email_address,
    cs.c_birth_year,
    SUM(cs.ws_sales_price * cs.ws_quantity) AS total_spent,
    MAX(cs.total_net_profit) AS max_profit,
    MIN(cs.returns_count) AS min_returns,
    String_agg(DISTINCT cs.stock_status, ', ') AS stock_summary
FROM CombinedStats cs
JOIN customer c ON cs.ws_item_sk = c.c_customer_sk
GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.c_email_address, cs.c_birth_year
HAVING SUM(cs.ws_sales_price * cs.ws_quantity) > 1000
ORDER BY total_spent DESC
LIMIT 10
OFFSET 5;
