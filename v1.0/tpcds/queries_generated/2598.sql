
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS SalesRank,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_sk) AS TotalNetProfit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        i.i_current_price > 0
        AND c.c_preferred_cust_flag = 'Y'
),
FilteredSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.TotalNetProfit,
        CASE 
            WHEN rs.SalesRank <= 5 THEN 'Top Sales'
            ELSE 'Other Sales'
        END AS SalesCategory
    FROM 
        RankedSales rs
)
SELECT 
    f.web_site_sk,
    f.SalesCategory,
    COUNT(*) AS SalesCount,
    AVG(f.ws_sales_price) AS AvgSalesPrice,
    SUM(f.ws_quantity) AS TotalQuantitySold,
    SUM(f.TotalNetProfit) AS TotalNetProfit
FROM 
    FilteredSales f
GROUP BY 
    f.web_site_sk, f.SalesCategory
HAVING 
    SUM(f.TotalNetProfit) > 1000
ORDER BY 
    f.web_site_sk, SalesCount DESC
