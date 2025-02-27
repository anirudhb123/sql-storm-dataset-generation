
WITH RECURSIVE sales_summary AS (
    SELECT ws_sold_date_sk, 
           SUM(ws_quantity) AS total_quantity_sold,
           SUM(ws_net_profit) AS total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales 
    GROUP BY ws_sold_date_sk
),
return_details AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returned_quantity,
           SUM(sr_return_amt) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
combined_sales AS (
    SELECT 
        ds.d_date AS sale_date,
        ss.total_quantity_sold,
        ss.total_net_profit,
        rd.total_returned_quantity,
        rd.total_returned_amount,
        COALESCE(ss.total_net_profit - rd.total_returned_amount, ss.total_net_profit) AS net_profit_adjusted
    FROM date_dim ds
    LEFT JOIN sales_summary ss ON ds.d_date_sk = ss.ws_sold_date_sk
    LEFT JOIN return_details rd ON ss.ws_sold_date_sk = rd.sr_item_sk
    WHERE ds.d_year = 2022
),
ranked_sales AS (
    SELECT *,
           RANK() OVER (ORDER BY net_profit_adjusted DESC) AS profit_rank
    FROM combined_sales
)
SELECT sale_date, 
       total_quantity_sold,
       net_profit_adjusted,
       profit_rank,
       CASE 
           WHEN total_returned_quantity IS NULL THEN 'No Returns'
           ELSE 'Returns Present'
       END AS return_status
FROM ranked_sales
WHERE profit_rank <= 10
ORDER BY net_profit_adjusted DESC;
