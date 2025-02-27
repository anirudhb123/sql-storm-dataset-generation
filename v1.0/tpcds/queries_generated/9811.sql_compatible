
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        wr.web_site_id,
        rs.total_net_profit,
        rs.total_orders
    FROM 
        RankedSales rs
    JOIN 
        web_site wr ON rs.web_site_sk = wr.web_site_sk
    WHERE 
        rs.rank <= 5
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    tw.total_orders, 
    w.warehouse_name,
    w.warehouse_sq_ft,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    AVG(sr.sr_return_amt) AS avg_return_amount
FROM 
    TopWebsites tw
JOIN 
    store_sales ss ON ss.ss_currency_sk = 1 
JOIN 
    warehouse w ON ss.ss_warehouse_sk = w.w_warehouse_sk
JOIN 
    customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_store_sk = ss.ss_store_sk
GROUP BY 
    tw.web_site_id, 
    tw.total_net_profit, 
    tw.total_orders,
    w.warehouse_name,
    w.warehouse_sq_ft,
    ca.ca_city,
    ca.ca_state
ORDER BY 
    tw.total_net_profit DESC;
