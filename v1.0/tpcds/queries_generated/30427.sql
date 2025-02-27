
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_return_time_sk,
        wr_item_sk,
        wr_return_quantity,
        wr_return_amt,
        1 AS return_level
    FROM 
        web_returns
    WHERE 
        wr_return_quantity IS NOT NULL
    UNION ALL
    SELECT 
        cr.returned_date_sk,
        cr.returned_time_sk,
        cr.item_sk,
        cr.return_quantity,
        cr.return_amount,
        cr.return_level + 1
    FROM 
        catalog_returns cr
    INNER JOIN 
        CustomerReturns crn ON cr.item_sk = crn.wr_item_sk
    WHERE 
        cr.return_quantity IS NOT NULL AND 
        crn.return_level < 5
), 
InventoryStats AS (
    SELECT 
        inv_warehouse_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_warehouse_sk
),
SalesStats AS (
    SELECT 
        ws_warehouse_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_warehouse_sk
),
ReturnStats AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_amt) AS total_returned_amt
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
),
CombinedStats AS (
    SELECT 
        is.inv_warehouse_sk,
        is.total_quantity,
        ss.total_net_profit,
        rs.total_returned_amt,
        COALESCE(ss.total_net_profit, 0) - COALESCE(rs.total_returned_amt, 0) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY is.inv_warehouse_sk ORDER BY (COALESCE(ss.total_net_profit, 0) - COALESCE(rs.total_returned_amt, 0)) DESC) AS rank
    FROM 
        InventoryStats is
    LEFT JOIN 
        SalesStats ss ON is.inv_warehouse_sk = ss.ws_warehouse_sk
    LEFT JOIN 
        ReturnStats rs ON rs.wr_returning_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_quantity,
    cs.total_net_profit,
    cs.total_returned_amt,
    cs.net_revenue
FROM 
    customer c
JOIN 
    CombinedStats cs ON c.c_customer_sk IN (SELECT wr_returning_customer_sk FROM web_returns)
WHERE 
    cs.rank = 1 
AND 
    c.c_current_addr_sk IS NOT NULL
ORDER BY 
    net_revenue DESC;
