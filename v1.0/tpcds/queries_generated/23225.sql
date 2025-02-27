
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS sale_rank
    FROM 
        customer_sales cs
),
filtered_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_profit
    FROM 
        ranked_sales r
    WHERE 
        r.sale_rank <= 10 OR 
        (r.sale_rank > 10 AND r.total_profit IS NOT NULL)
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    COALESCE(fc.total_profit, 0) AS adjusted_profit,
    (SELECT 
        COUNT(*) 
     FROM 
        store_sales ss
     WHERE 
        ss.ss_customer_sk = fc.c_customer_sk AND 
        ss.ss_sales_price > 100) AS high_value_sales,
    CASE
        WHEN fc.total_profit IS NULL THEN 'No Sales'
        WHEN fc.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    filtered_customers fc
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = fc.c_customer_sk)
WHERE 
    cd.cd_gender = 'F' AND 
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = fc.c_customer_sk) = 0
ORDER BY 
    fc.adjusted_profit DESC,
    fc.c_last_name ASC;
