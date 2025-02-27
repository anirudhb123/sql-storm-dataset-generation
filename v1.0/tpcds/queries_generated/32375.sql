
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
total_sales AS (
    SELECT 
        D.d_year,
        D.d_month_seq,
        I.i_item_id,
        I.i_item_desc,
        COALESCE(SUM(S.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(S.total_net_profit), 0.00) AS total_net_profit
    FROM 
        date_dim D
    LEFT JOIN 
        sales_data S ON D.d_date_sk = S.ws_sold_date_sk OR D.d_date_sk = S.cs_sold_date_sk
    LEFT JOIN 
        item I ON S.ws_item_sk = I.i_item_sk OR S.cs_item_sk = I.i_item_sk
    WHERE 
        D.d_year = 2023
    GROUP BY 
        D.d_year, D.d_month_seq, I.i_item_id, I.i_item_desc
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        total_sales
)
SELECT 
    T.d_year,
    T.d_month_seq,
    T.i_item_id,
    T.i_item_desc,
    T.total_quantity,
    T.total_net_profit,
    CASE 
        WHEN T.total_quantity IS NULL THEN 'No Sales'
        WHEN T.total_net_profit > 1000 THEN 'High Profit'
        WHEN T.total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    ranked_sales T
WHERE 
    T.profit_rank <= 10
ORDER BY 
    T.d_year, T.d_month_seq, T.total_net_profit DESC;
