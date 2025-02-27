
WITH RECURSIVE SalesTrends AS (
    SELECT 
        ws_item_sk,
        ws_ship_date_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ship_date_sk) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_ship_date_sk
    HAVING 
        SUM(ws_net_profit) > 0

    UNION ALL

    SELECT 
        cs_item_sk,
        cs_ship_date_sk,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_ship_date_sk) AS sales_rank
    FROM
        catalog_sales
    GROUP BY
        cs_item_sk, cs_ship_date_sk
    HAVING 
        SUM(cs_net_profit) > 0
),
DailySales AS (
    SELECT 
        d.d_date,
        SUM(st.total_profit) AS daily_profit
    FROM 
        date_dim d
    LEFT JOIN 
        SalesTrends st ON d.d_date_sk = st.ws_ship_date_sk OR d.d_date_sk = st.cs_ship_date_sk
    GROUP BY 
        d.d_date
),
TopDays AS (
    SELECT 
        d.d_date,
        ds.daily_profit,
        RANK() OVER (ORDER BY ds.daily_profit DESC) AS profit_rank
    FROM 
        DailySales ds
    JOIN 
        date_dim d ON ds.d_date = d.d_date
    WHERE 
        d.d_year = 2023
)
SELECT 
    td.d_date,
    td.daily_profit,
    CASE 
        WHEN td.profit_rank <= 10 THEN 'Top 10 Profit Days'
        ELSE 'Other Profit Days'
    END AS profit_category,
    NULLIF(td.daily_profit, 0) AS non_zero_profit
FROM 
    TopDays td
WHERE 
    td.profit_rank <= 10 OR td.daily_profit IS NOT NULL
ORDER BY 
    td.daily_profit DESC;
