
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = 20230101
    GROUP BY 
        ss_store_sk

    UNION ALL

    SELECT 
        ss.ss_store_sk, 
        sh.total_profit + SUM(ss.ss_net_profit) AS total_profit,
        sh.level + 1
    FROM 
        sales_hierarchy sh 
    JOIN 
        store_sales ss ON sh.ss_store_sk = ss.ss_store_sk 
    WHERE 
        ss.sold_date_sk = 20230101
    GROUP BY 
        ss.ss_store_sk, sh.total_profit, sh.level
)
, address_summary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
)
SELECT 
    sh.ss_store_sk,
    sh.total_profit,
    asum.unique_addresses,
    asum.avg_gmt_offset,
    DENSE_RANK() OVER (ORDER BY sh.total_profit DESC) AS sales_rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    address_summary asum ON sh.ss_store_sk = (SELECT COUNT(*) FROM store WHERE s_store_sk = sh.ss_store_sk)
WHERE 
    sh.total_profit IS NOT NULL
AND 
    EXISTS (
        SELECT 1 
        FROM web_returns wr 
        WHERE wr_returning_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = sh.ss_store_sk LIMIT 1)
    )
ORDER BY 
    sh.total_profit DESC
LIMIT 10;
