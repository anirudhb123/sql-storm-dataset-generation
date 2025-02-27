
WITH RECURSIVE Date_Range AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN '2020-01-01' AND '2020-12-31'
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    JOIN Date_Range dr ON d.d_date_sk = dr.d_date_sk + 1
),
Aggregate_Sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Order_Count,
        AVG(ws.ws_net_profit) AS Avg_Net_Profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_sales_price) DESC) AS Rank_Sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year IS NOT NULL
    GROUP BY d.d_year
),
Top_Stores AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_sales_price) AS Store_Sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_name
    ORDER BY Store_Sales DESC
    LIMIT 5
)
SELECT 
    d.d_date,
    d.d_year,
    asales.Total_Sales,
    asales.Order_Count,
    asales.Avg_Net_Profit,
    ts.Store_Sales,
    COALESCE(ts.Store_Sales, 0) - asales.Total_Sales AS Sales_Difference,
    CASE 
        WHEN asales.Total_Sales > 10000 THEN 'High Sale'
        WHEN asales.Total_Sales >= 5000 THEN 'Medium Sale'
        ELSE 'Low Sale'
    END AS Sale_Category
FROM Date_Range d
LEFT JOIN Aggregate_Sales asales ON d.d_year = asales.d_year
LEFT JOIN Top_Stores ts ON ts.Store_Sales = asales.Total_Sales
WHERE d.d_date IS NOT NULL OR ts.Store_Sales IS NULL
ORDER BY d.d_date;
