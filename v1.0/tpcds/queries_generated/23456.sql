
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as rn,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) as total_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
),
SalesWithReturns AS (
    SELECT 
        s.ws_item_sk,
        s.ws_order_number,
        s.ws_quantity,
        s.ws_net_profit,
        r.wr_return_quantity,
        r.wr_net_loss,
        (COALESCE(s.ws_net_profit, 0) - COALESCE(r.wr_net_loss, 0)) as final_profit
    FROM 
        RankedSales s
    LEFT JOIN 
        web_returns r 
    ON 
        s.ws_item_sk = r.wr_item_sk AND s.ws_order_number = r.wr_order_number
    WHERE 
        s.rn = 1
),
AggregateProfit AS (
    SELECT 
        ws_item_sk, 
        SUM(final_profit) as total_final_profit,
        COUNT(CASE WHEN final_profit < 0 THEN 1 END) as negative_profit_count
    FROM 
        SalesWithReturns
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ap.total_final_profit,
    ap.negative_profit_count,
    ca.ca_city,
    ca.ca_state,
    ABS(ap.total_final_profit) as absolute_profit,
    CASE 
        WHEN ap.negative_profit_count > 0 THEN 'Alert: Negative Profit'
        ELSE 'Profit is Positive'
    END as profit_status,
    CASE 
        WHEN absolute_profit > 1000 THEN 'High Profit'
        WHEN absolute_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END as profit_range
FROM 
    AggregateProfit ap
JOIN 
    item i ON i.i_item_sk = ap.ws_item_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = (SELECT TOP 1 cs.ss_customer_sk FROM store_sales cs WHERE cs.ss_item_sk = ap.ws_item_sk ORDER BY cs.ss_net_profit DESC))
WHERE 
    (ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL)
ORDER BY 
    total_final_profit DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
