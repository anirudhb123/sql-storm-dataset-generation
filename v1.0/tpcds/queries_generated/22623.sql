
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COUNT(DISTINCT cr_refunded_customer_sk) AS total_returns,
        COALESCE(CAST(SUM(cr_return_amount) AS DECIMAL(10, 2)), 0) AS total_return_amount,
        CASE 
            WHEN COUNT(DISTINCT cr_refunded_customer_sk) > 10 THEN 'Frequent Returner'
            ELSE 'Occasional Returner'
        END AS returner_type
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk AND wr.wr_item_sk = cr.cr_item_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.gender,
        cs.returner_type,
        SUM(cs.total_return_amount) AS total_return_amount
    FROM
        customer_summary cs
    WHERE 
        cs.gender IS NOT NULL AND cs.total_returns > 0
    GROUP BY 
        cs.c_customer_sk, cs.gender, cs.returner_type
),
item_sales AS (
    SELECT 
        i.i_item_id,
        r.total_sales,
        RANK() OVER (ORDER BY r.total_sales DESC) AS item_rank
    FROM
        item i
    JOIN 
        ranked_sales r ON i.i_item_sk = r.ws_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.gender,
    cs.returner_type,
    COUNT(DISTINCT is.item_rank) AS distinct_item_rank_count,
    MAX(is.total_sales) AS max_item_sales,
    AVG(is.total_sales) AS avg_item_sales
FROM 
    top_customers cs
LEFT JOIN 
    item_sales is ON cs.returner_type = 
    CASE 
        WHEN is.item_rank < 10 THEN 'Top Seller'
        ELSE 'Other'
    END
GROUP BY 
    cs.c_customer_sk, cs.gender, cs.returner_type
HAVING 
    AVG(is.total_sales) IS NOT NULL
    AND COUNT(DISTINCT is.item_rank) > 1
ORDER BY 
    max_item_sales DESC
LIMIT 20;
