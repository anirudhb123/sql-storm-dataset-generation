
WITH sales_data AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        DATEADD(DAY, 7, dd.d_date) AS future_sale_date -- 1 week ahead
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 
      AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY cs.cs_item_sk
), 
return_data AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
), 
combined_data AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        COALESCE(rd.total_returns, 0) AS total_returns,
        sd.avg_net_profit,
        sd.future_sale_date
    FROM sales_data sd
    LEFT JOIN return_data rd ON sd.cs_item_sk = rd.cr_item_sk
), 
ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.total_quantity,
        cs.total_returns,
        cs.avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN cs.total_returns > 0 THEN 'Returned' ELSE 'Not Returned' END ORDER BY cs.total_quantity DESC) as rank
    FROM combined_data cs
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cs.total_quantity,
    cs.total_returns,
    cs.avg_net_profit,
    RANK() OVER (ORDER BY cs.avg_net_profit DESC) AS profit_rank
FROM ranked_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE cs.rank <= 10 
  AND (cs.total_quantity > 50 OR cs.total_returns < 5) 
  AND (i.i_size IS NOT NULL OR i.i_color IS NULL)
ORDER BY profit_rank;
