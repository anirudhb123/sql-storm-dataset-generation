
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
TopItems AS (
    SELECT 
        i_item_id,
        r.total_quantity,
        r.total_profit,
        (r.total_profit / NULLIF(r.total_quantity, 0)) AS avg_profit_per_item
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
), 
SalesSummary AS (
    SELECT 
        ca_state,
        SUM(total_profit) AS state_profit,
        COUNT(DISTINCT TOPITEMS.i_item_id) AS unique_items
    FROM 
        TopItems
    JOIN 
        customer c ON c.c_customer_sk = WS.bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state
)
SELECT 
    ss.ca_state,
    ss.state_profit,
    ss.unique_items,
    COALESCE(NULLIF(AVG(state_profit), 0), 1) AS adjusted_avg_profit,
    CASE 
        WHEN ss.state_profit > (SELECT AVG(state_profit) FROM SalesSummary) 
        THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS performance_category
FROM 
    SalesSummary ss
ORDER BY 
    ss.state_profit DESC;
