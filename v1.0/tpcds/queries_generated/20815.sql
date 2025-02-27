
WITH RankedSales AS (
    SELECT 
        ws.customer_sk AS CustomerSK,
        ws.item_sk AS ItemSK,
        ws.net_profit AS NetProfit,
        RANK() OVER (PARTITION BY ws.customer_sk ORDER BY ws.net_profit DESC) AS ProfitRank,
        (SELECT COUNT(*) FROM web_sales ws_sub WHERE ws_sub.bill_customer_sk = ws.bill_customer_sk) AS TotalOrders
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
    )
), AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN ca.ca_state IN ('CA', 'NY', 'TX') THEN 'High'
            WHEN ca.ca_country = 'USA' AND ca.ca_state IS NULL THEN 'Unknown'
            ELSE 'Other'
        END AS AddressType
    FROM customer_address ca
), SalesWithAddresses AS (
    SELECT 
        rs.CustomerSK,
        rs.ItemSK,
        rs.NetProfit,
        ai.ca_city,
        ai.AddressType
    FROM RankedSales rs
    JOIN customer c ON c.c_customer_sk = rs.CustomerSK
    LEFT JOIN AddressInfo ai ON ai.ca_address_sk = c.c_current_addr_sk
    WHERE ai.AddressType IS NOT NULL OR rs.NetProfit > 10000
)

SELECT 
    s.ca_city,
    s.AddressType,
    SUM(s.NetProfit) AS TotalNetProfit,
    COUNT(*) AS CustomerCount,
    MAX(s.NetProfit) AS MaxNetProfit,
    MIN(s.NetProfit) AS MinNetProfit,
    COUNT(DISTINCT CASE WHEN s.TotalOrders > 5 THEN s.CustomerSK END) AS HighOrderCustomers
FROM SalesWithAddresses s
GROUP BY s.ca_city, s.AddressType
HAVING COUNT(s.CustomerSK) > 10
ORDER BY TotalNetProfit DESC 
LIMIT 10;
