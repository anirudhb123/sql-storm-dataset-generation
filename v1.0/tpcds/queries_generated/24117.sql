
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_profit_items AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        ranked_sales.total_net_profit
    FROM 
        item
    JOIN 
        ranked_sales ON item.i_item_sk = ranked_sales.ws_item_sk
    WHERE 
        ranked_sales.profit_rank <= 5
),
sales_and_returns AS (
    SELECT 
        h_item.i_item_id,
        h_item.i_product_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sales,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returns
    FROM 
        high_profit_items h_item
    LEFT JOIN 
        web_sales ws ON h_item.i_item_id = ws.ws_item_sk
    LEFT JOIN 
        catalog_returns cr ON h_item.i_item_id = cr.cr_item_sk
    GROUP BY 
        h_item.i_item_id, h_item.i_product_name
)
SELECT 
    sar.i_item_id,
    sar.i_product_name,
    sar.total_sales,
    sar.total_returns,
    CASE 
        WHEN sar.total_sales = 0 THEN NULL
        ELSE ROUND(sar.total_returns::decimal / NULLIF(sar.total_sales, 0), 2)
    END AS return_rate,
    (SELECT 
        COUNT(DISTINCT c.c_customer_id)
     FROM 
        customer c 
     WHERE 
        c.c_current_cdemo_sk IN (
            SELECT 
                cd_demo_sk 
            FROM 
                customer_demographics 
            WHERE 
                cd_marital_status = 'M' 
                AND cd_gender = 'F'
        ) 
        AND EXISTS (
            SELECT 1 
            FROM 
                store s 
            WHERE 
                s.s_city = 'New York' 
                AND s.s_state = 'NY'
                AND s.s_store_sk = ANY(ARRAY(
                    SELECT ss.ss_store_sk 
                    FROM store_sales ss 
                    WHERE ss.ss_item_sk = sar.i_item_id
                ))
        )
    ) AS returning_customers_count
FROM 
    sales_and_returns sar
WHERE 
    (sar.total_sales > 100 OR sar.total_returns > 10) 
    AND sar.total_returns < (SELECT AVG(total_returns) FROM sales_and_returns)
ORDER BY 
    return_rate DESC
LIMIT 10;
