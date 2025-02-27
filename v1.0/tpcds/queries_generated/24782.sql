
WITH RECURSIVE DateRanges AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date >= '2023-01-01' AND d_date < '2024-01-01'
    UNION ALL
    SELECT d_date_sk + 1, d_date + INTERVAL '1 DAY', d_year
    FROM DateRanges
    WHERE d_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
),
SalesData AS (
    SELECT 
        d.d_date,
        s.ss_item_sk,
        s.ss_sales_price,
        s.ss_ext_sales_price,
        COALESCE(s.ss_net_profit, 0) AS ss_net_profit,
        CASE 
            WHEN s.ss_sales_price > 100 THEN 'High'
            WHEN s.ss_sales_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS Price_Category,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY s.ss_sold_date_sk DESC) AS rn
    FROM store_sales s 
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
),
AggregatedSales AS (
    SELECT 
        d.d_date,
        AVG(sd.ss_sales_price) AS avg_price,
        SUM(sd.ss_net_profit) AS total_profit,
        COUNT(sd.ss_item_sk) AS item_count,
        SUM(CASE WHEN Price_Category = 'High' THEN 1 ELSE 0 END) AS high_price_sales
    FROM SalesData sd
    LEFT JOIN DateRanges d ON sd.d_date = d.d_date
    WHERE sd.rn = 1
    GROUP BY d.d_date
),
FinalOutput AS (
    SELECT 
        a.d_date,
        a.avg_price,
        a.total_profit,
        CASE 
            WHEN a.total_profit IS NULL THEN 'No Profit'
            WHEN a.total_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status,
        b.high_price_sales
    FROM AggregatedSales a
    LEFT JOIN (
        SELECT 
            COUNT(ss_item_sk) AS high_price_sales,
            ss_sold_date_sk
        FROM store_sales
        WHERE ss_sales_price > 100
        GROUP BY ss_sold_date_sk
    ) b ON b.ss_sold_date_sk = a.d_date
    ORDER BY a.d_date DESC
)
SELECT * FROM FinalOutput
WHERE (avg_price IS NOT NULL OR total_profit > 0) 
  AND (high_price_sales IS NULL OR high_price_sales < 10)
  AND (profit_status = 'Profit' OR profit_status = 'No Profit');
