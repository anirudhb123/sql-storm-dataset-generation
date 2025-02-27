
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk

    UNION ALL

    SELECT 
        sh.s_store_sk,
        ss.ss_sold_date_sk,
        sh.total_net_profit + ss.ss_net_profit AS total_net_profit,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales ss ON ss.s_store_sk = sh.s_store_sk
    WHERE 
        ss.ss_sold_date_sk = sh.ss_sold_date_sk + 1
),

profit_analysis AS (
    SELECT 
        sa.s_store_sk,
        sa.ss_sold_date_sk,
        ra.total_net_profit,
        DENSE_RANK() OVER (PARTITION BY sa.s_store_sk ORDER BY ra.total_net_profit DESC) AS profit_rank,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amt
    FROM 
        sales_hierarchy sa
    LEFT JOIN 
        store_returns sr ON sa.s_store_sk = sr.s_store_sk AND sa.ss_sold_date_sk = sr.sr_returned_date_sk
    GROUP BY 
        sa.s_store_sk, sa.ss_sold_date_sk, ra.total_net_profit
)

SELECT 
    c_last_name,
    c_first_name,
    cd_marital_status,
    cd_gender,
    d_date,
    p.total_net_profit,
    p.profit_rank,
    COALESCE(r.r_reason_desc, 'No Reason') AS return_reason,
    p.total_return_amt
FROM 
    profit_analysis p
JOIN 
    customer c ON p.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    date_dim d ON d.d_date_sk = p.ss_sold_date_sk
LEFT JOIN 
    reason r ON r.r_reason_sk = (
        SELECT sr_reason_sk 
        FROM store_returns sr 
        WHERE sr_store_sk = p.s_store_sk LIMIT 1
    )
WHERE 
    (cd.marital_status = 'M' AND cd_gender = 'F' AND cd.dep_count > 0)
    AND (p.total_net_profit / NULLIF(p.total_return_amt, 0) > 1 OR r.r_reason_desc IS NOT NULL)
ORDER BY 
    p.total_net_profit DESC
LIMIT 100;
