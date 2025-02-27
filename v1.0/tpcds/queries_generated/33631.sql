
WITH RECURSIVE Income_Categories AS (
    SELECT 
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN ib_lower_bound < 20000 THEN 'Low Income'
            WHEN ib_lower_bound BETWEEN 20000 AND 60000 THEN 'Middle Income'
            ELSE 'High Income'
        END AS Income_Level
    FROM income_band
    UNION ALL
    SELECT 
        ic.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN ib.ib_lower_bound < 20000 THEN 'Low Income'
            WHEN ib.ib_lower_bound BETWEEN 20000 AND 60000 THEN 'Middle Income'
            ELSE 'High Income'
        END AS Income_Level
    FROM Income_Categories ic
    JOIN income_band ib ON ic.hd_income_band_sk < ib.ib_income_band_sk
),
Sales_Summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        SUM(ws.ws_net_profit) AS Total_Profit,
        SUM(ws.ws_sales_price) AS Total_Sales,
        ic.Income_Level
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN Income_Categories ic ON hd.hd_income_band_sk = ic.hd_income_band_sk
    GROUP BY c.c_customer_sk, ic.Income_Level
),
Top_Sellers AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_sales_price) AS Monthly_Sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_sales_price) DESC) AS Sales_Rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    s.s_store_name,
    ss.Total_Orders,
    ss.Total_Profit,
    ss.Total_Sales,
    ts.Monthly_Sales,
    ts.Sales_Rank,
    ic.Income_Level
FROM Sales_Summary ss
JOIN store s ON ss.c_customer_sk = s.s_store_sk
LEFT JOIN Top_Sellers ts ON ts.Monthly_Sales = ss.Total_Sales
JOIN Income_Categories ic ON ss.Income_Level = ic.Income_Level
WHERE ss.Total_Orders IS NOT NULL
    AND (ts.Sales_Rank <= 5 OR ts.Monthly_Sales IS NULL)
ORDER BY ss.Total_Profit DESC, ts.Monthly_Sales DESC;
