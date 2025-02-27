
WITH RECURSIVE sales_winning AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
profit_top_items AS (
    SELECT 
        store_sk,
        item_sk,
        total_profit
    FROM 
        sales_winning
    WHERE 
        rank <= 10
)
SELECT 
    s.s_store_name,
    p.i_item_desc,
    p.i_current_price,
    pi.total_profit,
    COALESCE(r.r_reason_desc, 'No Reason') AS return_reason,
    CASE 
        WHEN pi.total_profit IS NULL THEN 'Insufficient Sales Data'
        ELSE 'Profit Calculated'
    END AS profit_status,
    CASE 
        WHEN pi.total_profit IS NOT NULL AND (SELECT SUM(cr_return_quantity) FROM catalog_returns cr WHERE cr.cr_item_sk = pi.item_sk) > 0 THEN 'Potential Return Item'
        ELSE 'Stable Product'
    END AS return_status,
    CONCAT('Total Profit: $', ROUND(pi.total_profit, 2)) AS profit_statement
FROM 
    profit_top_items pi
JOIN 
    store s ON s.s_store_sk = pi.store_sk
JOIN 
    item p ON p.i_item_sk = pi.item_sk
LEFT JOIN 
    reason r ON r.r_reason_sk IN (SELECT cr_reason_sk FROM catalog_returns cr WHERE cr.cr_item_sk = pi.item_sk)
ORDER BY 
    pi.total_profit DESC, s.s_store_name;
