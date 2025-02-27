
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) DESC) AS sales_rank
    FROM 
        web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL OR cs.cs_sold_date_sk IS NOT NULL OR ss.ss_sold_date_sk IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        d.d_date,
        SUM(s.total_sales) AS total_daily_sales,
        COUNT(DISTINCT s.ws_item_sk) AS unique_items_sold,
        AVG(s.total_sales) AS average_sales_per_item
    FROM 
        SalesData s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
RankedSales AS (
    SELECT 
        d.d_date,
        total_daily_sales,
        unique_items_sold,
        average_sales_per_item,
        RANK() OVER (ORDER BY total_daily_sales DESC) AS daily_sales_rank
    FROM 
        AggregatedSales d
)
SELECT 
    r.d_date,
    r.total_daily_sales,
    r.unique_items_sold,
    r.average_sales_per_item,
    CASE 
        WHEN r.daily_sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS sales_category
FROM 
    RankedSales r
WHERE 
    r.average_sales_per_item IS NOT NULL
AND 
    r.total_daily_sales > 1000
ORDER BY 
    r.d_date DESC;
