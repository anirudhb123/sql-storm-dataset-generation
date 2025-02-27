
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(cd.cd_gender, 'U') AS gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_demo_sk DESC) AS demo_rank
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
store_sales_summary AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_sales_price) AS total_sales, 
        AVG(ss_sales_price) AS avg_sales, 
        COUNT(DISTINCT ss_ticket_number) AS sale_count
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN 0 AND 365
    GROUP BY 
        ss_store_sk
),
high_sales_stores AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        s.s_city, 
        s.s_state, 
        s.s_zip,
        COALESCE(ss.total_sales, 0) AS total_sales
    FROM 
        store s 
    LEFT JOIN 
        store_sales_summary ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.total_sales IS NOT NULL 
        AND ss.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                store_sales_summary 
            WHERE 
                total_sales IS NOT NULL
        )
)
SELECT 
    cs.c_first_name, 
    cs.c_last_name, 
    COUNT(DISTINCT hss.s_store_sk) AS high_sales_store_count,
    STRING_AGG(DISTINCT CONCAT(hss.s_store_name, '(', hss.s_city, ', ', hss.s_state, ')') ORDER BY hss.s_store_name) AS high_sales_stores,
    SUM(CASE WHEN cs.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cs.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cs.gender IS NULL THEN 1 ELSE 0 END) AS unknown_gender_count
FROM 
    customer_summary cs 
JOIN 
    high_sales_stores hss ON cs.c_customer_sk = hss.s_store_sk
WHERE 
    cs.demo_rank = 1
    AND (cs.cd_purchase_estimate > 100 OR cs.cd_marital_status = 'M')
GROUP BY 
    cs.c_first_name, 
    cs.c_last_name
HAVING 
    COUNT(DISTINCT hss.s_store_sk) > 0
ORDER BY 
    high_sales_store_count DESC;
