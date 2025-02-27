
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (
            SELECT AVG(ws_inner.ws_sales_price) 
            FROM web_sales ws_inner 
            WHERE ws_inner.ws_web_site_sk = ws.ws_web_site_sk
        )
), HighProfitSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit <= 5
), SalesReason AS (
    SELECT 
        COALESCE(sr_reason.r_reason_desc, 'Unknown') AS reason_desc,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        store_returns sr
    LEFT JOIN 
        reason sr_reason ON sr.sr_reason_sk = sr_reason.r_reason_sk
    JOIN 
        store s ON sr.sr_store_sk = s.s_store_sk
    JOIN 
        web_sales ws ON sr.sr_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        s.s_closed_date_sk IS NULL
    GROUP BY 
        reason_desc
), Summary AS (
    SELECT 
        hps.web_site_sk,
        hps.ws_order_number,
        hps.ws_net_profit,
        sr.total_profit,
        CASE 
            WHEN sr.total_profit > 1000 THEN 'High'
            WHEN sr.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM 
        HighProfitSales hps
    LEFT JOIN 
        SalesReason sr ON hps.web_site_sk = sr.web_site_sk
)
SELECT 
    s.web_site_sk,
    s.ws_order_number,
    s.ws_net_profit,
    s.total_profit,
    s.profit_category,
    CASE 
        WHEN s.total_profit IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    Summary s
ORDER BY 
    s.ws_net_profit DESC, 
    s.total_profit DESC NULLS LAST
LIMIT 10;
