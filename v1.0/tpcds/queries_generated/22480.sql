
WITH recursive customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_customer_id
),
store_sales_data AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        AVG(ss.ss_quantity) AS avg_quantity_per_order
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
ranked_sales AS (
    SELECT 
        c.c_customer_id,
        cs.total_web_profit,
        COALESCE(ss.total_store_profit, 0) AS total_store_profit,
        RANK() OVER (ORDER BY cs.total_web_profit DESC) AS web_profit_rank
    FROM 
        customer_sales cs
    FULL OUTER JOIN 
        store_sales_data ss ON cs.c_customer_id = ss.s_store_sk
    WHERE 
        cs.total_web_profit > 1000 OR ss.total_store_profit > 1000
),
sales_summary AS (
    SELECT 
        r.c_customer_id,
        r.total_web_profit,
        r.total_store_profit,
        CASE 
            WHEN r.web_profit_rank IS NOT NULL AND r.total_store_profit > 0 THEN 'Hybrid'
            WHEN r.web_profit_rank IS NOT NULL THEN 'Web-Only'
            WHEN r.total_store_profit > 0 THEN 'Store-Only'
            ELSE 'No Sales'
        END AS sales_type
    FROM 
        ranked_sales r
    WHERE
        NOT EXISTS (SELECT 1 FROM warehouse WHERE w_warehouse_id = 'some_id')
)

SELECT 
    ss.c_customer_id,
    ss.total_web_profit,
    ss.total_store_profit,
    ss.sales_type,
    CASE 
        WHEN ss.sales_type = 'Hybrid' THEN 'Both'
        ELSE 'Individual'
    END AS sales_method,
    COALESCE(ss.total_web_profit - ss.total_store_profit, -1.00) AS profit_difference
FROM
    sales_summary ss
WHERE
    ss.total_web_profit IS NOT NULL 
    OR ss.total_store_profit IS NOT NULL
ORDER BY 
    profit_difference DESC
LIMIT 50;
