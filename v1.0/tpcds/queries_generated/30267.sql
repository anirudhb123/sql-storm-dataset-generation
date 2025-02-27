
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        SUM(ss.net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.sold_date_sk DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.sold_date_sk, ss.item_sk
),
high_sales_items AS (
    SELECT 
        sales_summary.item_sk,
        total_sales,
        total_profit
    FROM 
        sales_summary
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM sales_summary)
),
item_details AS (
    SELECT 
        i.item_sk,
        i.item_desc,
        i.current_price,
        COALESCE(hi.total_sales, 0) AS high_sales_total,
        COALESCE(hi.total_profit, 0) AS high_profit_total
    FROM 
        item i
    LEFT JOIN 
        high_sales_items hi ON i.item_sk = hi.item_sk
)
SELECT 
    id.item_desc,
    id.current_price,
    id.high_sales_total,
    id.high_profit_total,
    ROUND(id.high_profit_total / NULLIF(id.high_sales_total, 0), 2) AS profit_margin
FROM 
    item_details id
ORDER BY 
    profit_margin DESC
LIMIT 10;
