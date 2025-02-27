
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank,
        ws_net_profit,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_ship_mode_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458849 AND 2458880
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
ReturnImpact AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(cr.total_returned), 0) AS total_returned,
        (COALESCE(SUM(cr.total_return_amt), 0) / NULLIF(SUM(rs.ws_net_profit), 0)) * 100 AS return_ratio
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_item_sk = cr.sr_item_sk
    WHERE rs.profit_rank <= 5
    GROUP BY rs.ws_item_sk
    HAVING (COALESCE(SUM(cr.total_return_amt), 0) / NULLIF(SUM(rs.ws_net_profit), 0)) * 100 > 50 OR NULLIF(SUM(rs.ws_net_profit), 0) IS NULL
),
BestWorstRegions AS (
    SELECT 
        ca.ca_state,
        SUM(ri.total_net_profit) AS state_profit,
        CASE 
            WHEN SUM(ri.total_net_profit) > 10000 THEN 'Best'
            WHEN SUM(ri.total_net_profit) < 1000 THEN 'Worst'
            ELSE 'Average'
        END AS region_status
    FROM ReturnImpact ri
    JOIN customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ri.ws_item_sk LIMIT 1)
    JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_state
)
SELECT 
    br.ca_state,
    br.state_profit,
    br.region_status,
    CASE 
        WHEN br.region_status = 'Best' THEN 'Celebrate!'
        WHEN br.region_status = 'Worst' THEN 'Revamp Strategy'
        ELSE 'Steady Growth'
    END AS recommendation
FROM BestWorstRegions br
WHERE br.state_profit IS NOT NULL
ORDER BY br.state_profit DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
