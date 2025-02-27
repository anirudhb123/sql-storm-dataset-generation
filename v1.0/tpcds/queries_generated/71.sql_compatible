
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_ext_sales_price, 
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
),
CustomerReturns AS (
    SELECT 
        wr.wr_returned_date_sk, 
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS TotalReturns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returned_date_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        COUNT(DISTINCT c.c_customer_sk) AS CustomerCount
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
),
ProfitMargins AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS TotalNetProfit,
        SUM(ss.ss_ext_sales_price) AS TotalSalesPrice,
        CASE 
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN NULL 
            ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price) 
        END AS ProfitMargin
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    COALESCE(cr.TotalReturns, 0) AS TotalReturns,
    COUNT(DISTINCT rs.ws_order_number) AS TotalOrders,
    SUM(rs.ws_ext_sales_price) AS TotalSales,
    AVG(pm.ProfitMargin) AS AvgProfitMargin
FROM 
    AddressInfo ai
LEFT JOIN 
    CustomerReturns cr ON cr.wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk IN (SELECT pm.ss_item_sk FROM ProfitMargins pm)
LEFT JOIN 
    ProfitMargins pm ON pm.ss_item_sk = rs.ws_item_sk
GROUP BY 
    ai.ca_city, ai.ca_state, ai.ca_country
HAVING 
    SUM(rs.ws_ext_sales_price) > (SELECT AVG(ws.ws_net_paid) FROM web_sales ws WHERE ws.ws_ship_date_sk IS NOT NULL)
ORDER BY 
    TotalSales DESC
FETCH FIRST 10 ROWS ONLY;
