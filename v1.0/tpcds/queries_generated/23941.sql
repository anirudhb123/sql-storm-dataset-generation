
WITH ranked_sales AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        ws.quantity,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY ws.net_profit DESC) AS rank_profit,
        SUM(ws.net_profit) OVER (PARTITION BY ws.item_sk) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 20200101 AND 20201231
),
total_return AS (
    SELECT 
        wr.item_sk,
        SUM(wr.return_quantity) AS total_returned
    FROM 
        web_returns wr
    WHERE 
        wr.returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        wr.item_sk
),
customer_info AS (
    SELECT 
        c.customer_sk,
        cd.gender,
        cd.marital_status,
        COALESCE(hd.income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT c.customer_sk) AS num_customers,
    SUM(rs.net_profit) AS total_net_profit,
    COALESCE(SUM(tr.total_returned), 0) AS total_returns,
    ROUND(AVG(rs.total_profit), 2) AS avg_profit_per_item
FROM 
    customer_info c
JOIN 
    ranked_sales rs ON c.customer_sk = rs.sold_date_sk
JOIN 
    store s ON s.store_sk = rs.item_sk
JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    total_return tr ON tr.item_sk = rs.item_sk
WHERE 
    (c.gender = 'M' OR c.marital_status = 'S') 
    AND (rs.rank_profit = 1 OR (rs.rank_profit > 1 AND rs.net_profit < 0))
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT c.customer_sk) > 5
ORDER BY 
    total_net_profit DESC, ca.city ASC;
