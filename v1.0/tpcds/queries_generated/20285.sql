
WITH RankedSales AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        COUNT(*) OVER (PARTITION BY ws.ws_web_site_sk) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
        AND c.c_first_shipto_date_sk IS NOT NULL
),
StoreProfit AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_store_sk
),
WebReturnStats AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS total_returns
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_web_page_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(p.total_profit, 0) AS store_profit,
    COALESCE(s.quantity_sold, 0) AS web_sales_quantity,
    ROUND(AVG(CASE WHEN r.total_sales IS NULL THEN NULL ELSE r.ws_net_profit END), 2) AS avg_web_profit,
    ws.total_returns,
    ws.avg_return_quantity,
    CASE 
        WHEN s.sales_count >= 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    customer_address a
LEFT JOIN 
    StoreProfit p ON a.ca_address_sk = p.s_store_sk
LEFT JOIN 
    (SELECT 
         ws.ws_bill_customer_sk,
         SUM(ws.ws_quantity) AS quantity_sold
     FROM 
         web_sales ws
     GROUP BY 
         ws.ws_bill_customer_sk) s ON a.ca_address_sk = s.ws_bill_customer_sk
LEFT JOIN 
    WebReturnStats ws ON a.ca_address_sk = ws.wr_web_page_sk
LEFT JOIN 
    RankedSales r ON a.ca_address_sk = r.ws_web_site_sk
WHERE 
    a.ca_state IS NOT NULL
    AND a.ca_city IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = 'CA')
GROUP BY 
    a.ca_city, 
    a.ca_state, 
    p.total_profit, 
    s.quantity_sold, 
    ws.total_returns, 
    ws.avg_return_quantity
HAVING 
    COUNT(DISTINCT a.ca_address_sk) > 10
ORDER BY 
    store_profit DESC, 
    avg_web_profit DESC NULLS LAST;
