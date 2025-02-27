
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss.store_sk,
        ss.sales_price,
        1 AS level,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY ss.net_profit DESC) AS rn
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk = (SELECT MAX(ss1.sold_date_sk) FROM store_sales ss1)
    UNION ALL
    SELECT 
        s.store_sk,
        s.sales_price * 0.9 AS sales_price, 
        sh.level + 1,
        ROW_NUMBER() OVER (PARTITION BY s.store_sk ORDER BY s.net_profit DESC) AS rn
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON sh.store_sk = s.store_sk
    WHERE 
        sh.level < 5
),
average_sales AS (
    SELECT 
        store_sk,
        AVG(sales_price) AS avg_sales_price
    FROM 
        sales_hierarchy
    GROUP BY 
        store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
        SUM(CASE 
                WHEN ws.ws_sales_price > 100 THEN 1 
                ELSE 0 
            END) AS high_value_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    a.store_sk,
    a.avg_sales_price,
    c.gender,
    c.high_value_purchases,
    RANK() OVER (ORDER BY a.avg_sales_price DESC) AS sales_rank
FROM 
    average_sales a
LEFT JOIN 
    customer_info c ON c.c_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_sales_price BETWEEN 50 AND 150
    )
WHERE 
    a.avg_sales_price IS NOT NULL
    AND c.high_value_purchases > 5
ORDER BY 
    sales_rank;
