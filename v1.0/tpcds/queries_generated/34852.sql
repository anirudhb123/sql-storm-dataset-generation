
WITH RECURSIVE SalesOverview AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        COALESCE(SUM(os.total_quantity), 0) AS total_web_sold,
        COALESCE(SUM(os.total_sales), 0) AS total_web_revenue
    FROM 
        item i
    LEFT JOIN SalesOverview os ON i.i_item_sk = os.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price, i.i_brand, i.i_category
),
TopItems AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_web_revenue DESC) AS rank_performance
    FROM 
        ItemDetails
    WHERE 
        total_web_sold > 0
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    t.i_item_desc,
    t.total_web_sold,
    t.total_web_revenue,
    CASE 
        WHEN t.total_web_revenue > 10000 THEN 'High Performer'
        WHEN t.total_web_revenue > 5000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    TopItems t
JOIN 
    customer ci ON ci.c_customer_sk = (SELECT c_customer_sk FROM web_sales WHERE ws_item_sk = t.i_item_sk LIMIT 1)
WHERE 
    t.rank_performance <= 10
ORDER BY 
    t.total_web_revenue DESC;
