
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, 1 AS Level
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, ch.Level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        d.d_date AS SaleDate,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
),
CustomerSales AS (
    SELECT 
        ch.c_customer_sk,
        SUM(sd.ws_net_profit) AS TotalProfit,
        COUNT(DISTINCT sd.ws_order_number) AS TotalOrders
    FROM CustomerHierarchy ch
    LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY ch.c_customer_sk
),
AggregateSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.TotalProfit,
        cs.TotalOrders,
        COALESCE(NULLIF(cs.TotalProfit / NULLIF(cs.TotalOrders, 0), 0), 0) AS AvgProfitPerOrder,
        CASE 
            WHEN cs.TotalOrders = 0 THEN 'No Orders'
            WHEN cs.TotalProfit > 1000 THEN 'High Value Customer'
            WHEN cs.TotalProfit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
            ELSE 'Low Value Customer'
        END AS CustomerValueCategory
    FROM CustomerSales cs
)
SELECT 
    a.c_customer_sk,
    a.TotalProfit,
    a.TotalOrders,
    a.AvgProfitPerOrder,
    a.CustomerValueCategory,
    COALESCE(a.CustomerValueCategory, 'Unknown') AS ValueCategoryReport,
    COUNT(DISTINCT IF(sd.ProfitRank = 1, sd.ws_order_number, NULL)) AS TopProfitableOrders
FROM AggregateSales a
LEFT JOIN SalesData sd ON a.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY a.c_customer_sk, a.TotalProfit, a.TotalOrders, a.AvgProfitPerOrder, a.CustomerValueCategory
HAVING TotalProfit IS NOT NULL
ORDER BY a.TotalProfit DESC;
