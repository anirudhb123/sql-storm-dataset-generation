
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ranked_sales.total_quantity,
        ranked_sales.total_sales
    FROM 
        ranked_sales
    JOIN 
        item ON ranked_sales.ws_item_sk = item.i_item_sk
    WHERE 
        ranked_sales.sales_rank <= 10
),
store_summary AS (
    SELECT 
        s_store_sk,
        AVG(ss_net_profit) AS avg_net_profit,
        MAX(ss_sales_price) AS max_sales_price
    FROM 
        store_sales 
    GROUP BY 
        s_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        CASE 
            WHEN cd.cd_dep_count > 3 THEN 'Large Family'
            WHEN cd.cd_dep_count = 0 THEN 'Single'
            ELSE 'Average Family'
        END AS family_size
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    hi.i_item_id,
    hi.i_item_desc,
    hi.total_quantity,
    hi.total_sales,
    ss.avg_net_profit,
    ss.max_sales_price,
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ci.marital_status,
    ci.family_size
FROM 
    high_value_sales hi
JOIN 
    store_summary ss ON hi.total_sales > ss.avg_net_profit 
LEFT JOIN 
    customer_info ci ON hi.total_quantity > (SELECT AVG(total_quantity) FROM high_value_sales)
WHERE 
    (ci.c_customer_sk IS NULL OR ci.marital_status <> 'N/A')
    AND (hi.total_sales IS NOT NULL OR hi.total_quantity IS NOT NULL)
ORDER BY 
    hi.total_sales DESC, hi.total_quantity ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
