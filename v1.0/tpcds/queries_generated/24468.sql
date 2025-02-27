
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_item_sk
),
sales_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
combined_sales AS (
    SELECT 
        it.i_item_sk,
        COALESCE(isales.total_quantity, 0) AS total_quantity,
        COALESCE(isales.total_sales, 0) AS total_sales,
        COALESCE(returns.total_returns, 0) AS total_returns,
        COALESCE(returns.total_return_amount, 0) AS total_return_amount
    FROM 
        item it
    LEFT JOIN 
        item_sales isales ON it.i_item_sk = isales.ws_item_sk
    LEFT JOIN 
        sales_returns returns ON it.i_item_sk = returns.sr_item_sk
),
final_result AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.marital_category,
        cs.dependent_count,
        cs.gender_rank,
        co.total_quantity,
        co.total_sales,
        co.total_returns,
        co.total_return_amount,
        CASE 
            WHEN co.total_sales - co.total_return_amount < 0 THEN NULL 
            ELSE co.total_sales - co.total_return_amount
        END AS net_sales
    FROM 
        customer_stats cs
    JOIN 
        combined_sales co ON cs.c_customer_id IN (
            SELECT 
                DISTINCT ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_bill_customer_sk IS NOT NULL
            UNION 
            SELECT 
                DISTINCT ss_customer_sk 
            FROM 
                store_sales 
            WHERE 
                ss_customer_sk IS NOT NULL
        ) 
    WHERE 
        cs.gender_rank <= 10 AND cs.dependent_count IS NOT NULL
)
SELECT *
FROM final_result
WHERE 
    marital_category = 'Married' 
    OR (net_sales IS NOT NULL AND net_sales > 1000)
ORDER BY 
    net_sales DESC, c_customer_id 
LIMIT 50;
