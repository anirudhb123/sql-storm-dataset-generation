
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        CASE 
            WHEN sd.profit_rank = 1 THEN 'Top Seller'
            WHEN sd.profit_rank = 2 THEN 'Second Best'
            ELSE 'Other'
        END AS sale_category,
        COALESCE(pd.p_promo_name, 'No Promotion') AS promotional_info
    FROM sales_data sd
    LEFT JOIN promotion pd ON sd.ws_item_sk = pd.p_item_sk
    WHERE sd.total_profit > (
        SELECT AVG(total_profit) 
        FROM sales_data 
        WHERE profit_rank <= 2
    )
),
final_report AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit,
        rs.sale_category,
        SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT rs.promotional_info ORDER BY rs.promotional_info SEPARATOR ', '), ',', 5) AS promotional_names,
        COUNT(DISTINCT wr_returning_customer_sk) AS unique_returning_customers
    FROM ranked_sales rs
    LEFT JOIN web_returns wr ON rs.ws_item_sk = wr.wr_item_sk
    GROUP BY rs.ws_item_sk
    ORDER BY rs.total_profit DESC
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_profit,
    fr.sale_category,
    fr.promotional_names,
    fr.unique_returning_customers,
    CASE 
        WHEN fr.unique_returning_customers IS NULL THEN 'No Returns'
        WHEN fr.unique_returning_customers < 5 THEN 'Few Returns'
        ELSE 'Frequent Returns'
    END AS return_frequency
FROM final_report fr
WHERE fr.return_frequency != 'No Returns' OR fr.total_profit > 1000
ORDER BY fr.total_profit DESC,
         fr.unique_returning_customers ASC;
