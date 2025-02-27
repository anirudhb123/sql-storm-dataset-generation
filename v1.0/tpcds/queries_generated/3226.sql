
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 10000
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
store_sales_data AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_net_profit) AS total_store_net_profit
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
),
combined_sales AS (
    SELECT 
        COALESCE(w.ws_sold_date_sk, s.ss_sold_date_sk) AS sold_date_sk,
        COALESCE(w.ws_item_sk, s.ss_item_sk) AS item_sk,
        COALESCE(w.total_quantity, 0) AS total_web_quantity,
        COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
        (COALESCE(w.total_net_profit, 0) + COALESCE(s.total_store_net_profit, 0)) AS total_net_profit
    FROM 
        sales_data w
    FULL OUTER JOIN 
        store_sales_data s ON w.ws_sold_date_sk = s.ss_sold_date_sk AND w.ws_item_sk = s.ss_item_sk
),
ranked_sales AS (
    SELECT 
        sold_date_sk,
        item_sk,
        total_web_quantity,
        total_store_quantity,
        total_net_profit,
        RANK() OVER (PARTITION BY sold_date_sk ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        combined_sales
)
SELECT 
    cs.sold_date_sk,
    cs.item_sk,
    cs.total_web_quantity,
    cs.total_store_quantity,
    cs.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    CASE 
        WHEN cs.total_net_profit > 1000 THEN 'High Profit'
        WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM 
    ranked_sales cs
LEFT JOIN 
    customer_demographics cd ON cs.total_store_quantity > 0 AND cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = cs.item_sk LIMIT 1)
WHERE 
    cs.profit_rank <= 5 OR cs.profit_rank IS NULL
ORDER BY 
    cs.sold_date_sk, cs.total_net_profit DESC;
