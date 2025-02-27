
WITH SalesSummary AS (
    SELECT 
        d.d_year AS SalesYear,
        d.d_month_seq AS SalesMonth,
        c.c_gender AS Gender,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        SUM(ws.ws_ext_discount_amt) AS TotalDiscounts,
        AVG(ws.ws_net_profit) AS AvgNetProfit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year, d.d_month_seq, c.c_gender
),
SalesRanked AS (
    SELECT 
        SalesYear, 
        SalesMonth, 
        Gender,
        TotalOrders,
        TotalSales,
        TotalDiscounts,
        AvgNetProfit,
        RANK() OVER (PARTITION BY SalesYear ORDER BY TotalSales DESC) AS SalesRank
    FROM SalesSummary
)
SELECT 
    SalesYear, 
    SalesMonth, 
    Gender, 
    TotalOrders, 
    TotalSales, 
    TotalDiscounts, 
    AvgNetProfit
FROM SalesRanked
WHERE SalesRank <= 5
ORDER BY SalesYear, TotalSales DESC;
