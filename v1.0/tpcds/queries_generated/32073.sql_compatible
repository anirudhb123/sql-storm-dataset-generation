
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        1 AS level
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ss.ss_item_sk
    UNION ALL
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) + cte.total_quantity_sold,
        SUM(ss.ss_ext_sales_price) + cte.total_sales_amount,
        cte.level + 1
    FROM 
        store_sales ss
    INNER JOIN sales_cte cte ON ss.ss_item_sk = cte.ss_item_sk
    WHERE 
        cte.level < 5
    GROUP BY 
        ss.ss_item_sk, cte.total_quantity_sold, cte.total_sales_amount, cte.level
),
sales_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(sales_totals.total_quantity_sold, 0) AS total_quantity,
        COALESCE(sales_totals.total_sales_amount, 0) AS total_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(sales_totals.total_sales_amount, 0) DESC) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        (SELECT 
            ss.ss_item_sk,
            SUM(ss.ss_quantity) AS total_quantity_sold,
            SUM(ss.ss_ext_sales_price) AS total_sales_amount
        FROM 
            store_sales ss
        GROUP BY 
            ss.ss_item_sk) sales_totals ON i.i_item_sk = sales_totals.ss_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
)
SELECT 
    s.i_item_id,
    s.i_item_desc,
    s.total_quantity,
    s.total_sales,
    CASE 
        WHEN s.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS sales_category,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS sales_value_category
FROM 
    sales_summary s
WHERE 
    s.total_sales IS NOT NULL
ORDER BY 
    s.sales_rank
LIMIT 50;
