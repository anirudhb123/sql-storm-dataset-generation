
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        1 AS hierarchy_level
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2450599

    UNION ALL

    SELECT 
        ss2.ss_item_sk,
        ss2.ss_sold_date_sk,
        ss2.ss_quantity + sh.ss_quantity,
        ss2.ss_net_paid + sh.ss_net_paid,
        ss2.ss_net_profit + sh.ss_net_profit,
        sh.hierarchy_level + 1
    FROM 
        store_sales ss2
    JOIN 
        sales_hierarchy sh ON ss2.ss_item_sk = sh.ss_item_sk
    WHERE 
        sh.hierarchy_level < 5
),

customer_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr 
    GROUP BY 
        cr.cr_item_sk
),

item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(sh.ss_quantity), 0) AS total_sold,
        COALESCE(SUM(cr.total_returns), 0) AS total_returns,
        COALESCE(SUM(cr.total_return_amount), 0) AS total_return_amount,
        ROUND(COALESCE(SUM(sh.ss_net_profit), 0) - COALESCE(SUM(cr.total_return_amount), 0), 2) AS net_profit
    FROM 
        item i
    LEFT JOIN 
        sales_hierarchy sh ON i.i_item_sk = sh.ss_item_sk
    LEFT JOIN 
        customer_returns cr ON i.i_item_sk = cr.cr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)

SELECT 
    *,
    CASE 
        WHEN total_returns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN net_profit < 0 THEN 'Loss'
        WHEN net_profit >= 0 AND total_sold > 100 THEN 'High Profit'
        ELSE 'Moderate Profit'
    END AS profit_status
FROM 
    item_summary
WHERE 
    total_sold > (SELECT AVG(total_sold) FROM item_summary)
ORDER BY 
    net_profit DESC;
