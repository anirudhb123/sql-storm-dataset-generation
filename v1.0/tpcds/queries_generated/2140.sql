
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_dow IN (1, 2, 3, 4, 5)
        )
),
SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) as total_profit,
        COUNT(DISTINCT ws.ws_order_number) as total_orders,
        AVG(ws.ws_net_profit) as average_profit
    FROM 
        RankedSales ws
    WHERE 
        ws.rank <= 10
    GROUP BY 
        ws.web_site_sk
),
CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        MAX(CASE WHEN cd.cd_gender = 'M' THEN cd.cd_purchase_estimate ELSE 0 END) AS male_purchase_estimate,
        MAX(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_purchase_estimate ELSE 0 END) AS female_purchase_estimate
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk
),
ReturnStats AS (
    SELECT 
        sr.store_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.store_sk
)
SELECT 
    ws.web_site_sk,
    ss.total_profit,
    ss.total_orders,
    ss.average_profit,
    cp.male_purchase_estimate,
    cp.female_purchase_estimate,
    rs.total_returns,
    rs.total_return_amt
FROM 
    SalesSummary ss
JOIN 
    CustomerPurchase cp ON cp.c_customer_sk = ss.web_site_sk
LEFT JOIN 
    ReturnStats rs ON rs.store_sk = ss.web_site_sk
WHERE 
    ss.total_profit IS NOT NULL 
    AND ss.total_orders > 5
ORDER BY 
    ss.total_profit DESC;
