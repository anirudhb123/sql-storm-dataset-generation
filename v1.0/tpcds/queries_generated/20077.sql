
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COUNT(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name)) AS customer_count,
        SUM(IF(cd.cd_marital_status = 'M', 1, 0)) AS married_count,
        SUM(IF(cd.cd_education_status IS NULL, 0, 1)) AS educated_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
)
SELECT 
    ci.gender,
    COUNT(DISTINCT ci.c_customer_sk) AS total_customers,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    SUM(rs.ws_quantity) AS total_quantity_sold,
    SUM(CASE WHEN rs.profit_rank = 1 THEN rs.ws_net_profit ELSE 0 END) AS top_profit
FROM 
    customer_info ci
JOIN 
    ranked_sales rs ON ci.c_customer_sk = (SELECT c_customer_sk 
                                             FROM web_sales 
                                             WHERE ws_item_sk = rs.ws_item_sk 
                                             LIMIT 1)
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT ss_store_sk FROM store_sales WHERE ss_item_sk = rs.ws_item_sk LIMIT 1)
WHERE 
    s.s_closed_date_sk IS NULL OR s.s_closed_date_sk IS NULL
GROUP BY 
    ci.gender
HAVING 
    total_quantity_sold > 100
UNION ALL
SELECT 
    'Total' AS gender,
    SUM(CASE WHEN ci.gender IS NULL THEN 1 ELSE 0 END) AS total_customers,
    AVG(COALESCE(rs.ws_sales_price, 0)) AS avg_sales_price,
    SUM(COALESCE(rs.ws_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(CASE WHEN rs.profit_rank = 1 THEN rs.ws_net_profit ELSE NULL END, 0)) AS top_profit
FROM 
    ranked_sales rs
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk = (SELECT c_customer_sk 
                                             FROM web_sales 
                                             WHERE ws_item_sk = rs.ws_item_sk 
                                             LIMIT 1)
WHERE 
    rs.ws_quantity > 0;
