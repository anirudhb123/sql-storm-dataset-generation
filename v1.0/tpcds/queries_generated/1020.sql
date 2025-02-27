
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 50
        AND ws.ws_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.total_quantity) AS total_quantity_sold,
        SUM(rs.total_net_profit) AS total_net_profit,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        MAX(rs.profit_rank) AS highest_profit_rank,
        COALESCE(MAX(rs.unique_customers), 0) AS unique_customer_count
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    s.i_item_id,
    ss.total_quantity_sold,
    ss.total_net_profit,
    ss.total_orders,
    ss.highest_profit_rank,
    ss.unique_customer_count,
    CASE 
        WHEN ss.total_net_profit > 1000 THEN 'High Profits'
        WHEN ss.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profits'
        ELSE 'Low Profits'
    END AS profitability_category
FROM 
    SalesSummary ss
JOIN 
    item s ON ss.ws_item_sk = s.i_item_sk
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10
UNION ALL
SELECT 
    'Aggregate' AS i_item_id,
    SUM(total_quantity_sold) AS total_quantity_sold,
    SUM(total_net_profit) AS total_net_profit,
    SUM(total_orders) AS total_orders,
    NULL AS highest_profit_rank,
    SUM(unique_customer_count) AS unique_customer_count,
    CASE 
        WHEN SUM(total_net_profit) > 10000 THEN 'High Profits'
        ELSE 'Low Profits'
    END AS profitability_category
FROM 
    SalesSummary;
