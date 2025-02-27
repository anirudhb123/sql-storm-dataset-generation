
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_sk, 
        ws_order_number, 
        total_quantity, 
        total_profit
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    w.warehouse_id,
    ca.ca_city, 
    ca.ca_state,
    COALESCE(ts.total_quantity, 0) AS web_total_quantity,
    COALESCE(ts.total_profit, 0) AS web_total_profit,
    CASE 
        WHEN ts.total_profit > 1000 THEN 'High Profit'
        WHEN ts.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    warehouse w
LEFT JOIN 
    customer_address ca ON w.warehouse_sk = ca.ca_address_sk
LEFT JOIN 
    TopSales ts ON w.warehouse_sk = ts.web_site_sk
WHERE 
    w.warehouse_sq_ft > 5000
ORDER BY 
    profit_category DESC, web_total_profit DESC;
