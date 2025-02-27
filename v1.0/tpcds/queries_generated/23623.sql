
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    LEFT JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        ws.web_site_sk
),
HighProfit_sites AS (
    SELECT 
        web_site_sk,
        total_orders,
        total_profit 
    FROM 
        RankedSales
    WHERE 
        profit_rank = 1
),
SalesDetails AS (
    SELECT 
        s.store_sk,
        SUM(ss.net_profit) AS store_profit,
        SUM(ss.quantity) AS total_items_sold,
        COUNT(DISTINCT ss.ticket_number) AS total_sales_transactions
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON ss.store_sk = s.store_sk
    GROUP BY 
        s.store_sk
)
SELECT 
    w.web_name AS Website,
    w.web_id AS Web_ID,
    h.total_orders AS Web_Total_Orders,
    h.total_profit AS Web_Total_Profit,
    s.store_profit AS Store_Profit,
    s.total_items_sold AS Items_Sold,
    s.total_sales_transactions AS Transactions,
    CASE 
        WHEN h.total_profit IS NULL THEN 'No Sales'
        WHEN s.store_profit IS NULL THEN 'Store Not Found'
        ELSE 'Sales Data Available'
    END AS Sales_Status
FROM 
    HighProfit_sites h
JOIN 
    web_site w ON h.web_site_sk = w.web_site_sk
LEFT JOIN 
    SalesDetails s ON w.web_site_sk = s.store_sk
WHERE 
    (h.total_profit - COALESCE(s.store_profit, 0)) > 1000
    OR (s.total_items_sold > 500 AND s.total_sales_transactions >= 10)
ORDER BY 
    w.web_name COLLATE Latin1_General_BIN;
