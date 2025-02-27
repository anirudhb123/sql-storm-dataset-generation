
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        d_year,
        d_month_seq
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        ws_item_sk, d_year, d_month_seq
    HAVING 
        SUM(ws_quantity) > 0
),
ranked_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_sales,
        RANK() OVER (PARTITION BY sales.d_year ORDER BY sales.total_sales DESC) AS sales_rank
    FROM 
        sales_data sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
),
sales_summary AS (
    SELECT 
        d_year,
        COUNT(*) AS rank_below_10,
        AVG(total_sales) AS avg_sales_above_1000
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10 AND total_sales > 1000
    GROUP BY 
        d_year
)
SELECT 
    ds.d_year,
    ds.rank_below_10,
    ds.avg_sales_above_1000,
    SUM(IFNULL(ss.rank_below_10, 0)) AS total_rank_below_10,
    COALESCE(MIN(ss.avg_sales_above_1000), 0) AS minimum_avg_sales
FROM 
    sales_summary ss 
FULL OUTER JOIN 
    (SELECT DISTINCT d_year FROM date_dim) ds ON ds.d_year = ss.d_year
GROUP BY 
    ds.d_year, ds.rank_below_10, ds.avg_sales_above_1000
ORDER BY 
    ds.d_year DESC;
