
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        sales.total_quantity, 
        sales.total_profit
    FROM SalesCTE sales
    JOIN item ON sales.ws_item_sk = item.i_item_sk
    WHERE sales.profit_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
),
HighDemandItems AS (
    SELECT 
        t.id AS item_id, 
        t.total_quantity, 
        COALESCE(r.total_returns, 0) AS total_returns,
        (t.total_quantity - COALESCE(r.total_returns, 0)) AS net_sold
    FROM TopItems t
    LEFT JOIN CustomerReturns r ON t.ws_item_sk = r.sr_item_sk
    WHERE net_sold > 0
),
FinalReport AS (
    SELECT 
        hi.item_id, 
        hi.total_quantity, 
        hi.total_returns, 
        hi.net_sold,
        CASE 
            WHEN hi.net_sold > 100 THEN 'High Demand'
            WHEN hi.net_sold BETWEEN 50 AND 100 THEN 'Moderate Demand'
            ELSE 'Low Demand' 
        END AS demand_category
    FROM HighDemandItems hi
)
SELECT 
    f.item_id,
    f.total_quantity,
    f.total_returns,
    f.net_sold,
    f.demand_category,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count
FROM FinalReport f
JOIN catalog_sales cs ON f.item_id = cs.cs_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    f.item_id, 
    f.total_quantity, 
    f.total_returns, 
    f.net_sold, 
    f.demand_category,
    ca.ca_city, 
    ca.ca_state
ORDER BY f.net_sold DESC
LIMIT 10;
