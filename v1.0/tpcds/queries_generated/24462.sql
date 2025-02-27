
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating,
        COALESCE(cd.cd_dep_count, 0) AS total_dependents,
        COALESCE(cd.cd_dep_college_count, 0) AS college_dependents,
        SUM(COALESCE(ws.ws_net_profit, 0)) OVER (PARTITION BY c.c_customer_sk) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        (cd.cd_marital_status IS NOT NULL OR cd.cd_credit_rating IS NOT NULL)
        AND (cd.cd_dep_count > 2 OR cd.cd_credit_rating = 'Excellent')
),
date_summary AS (
    SELECT 
        d.d_date_sk,
        d.d_year, 
        d.d_month_seq, 
        MAX(ws.ws_net_profit) AS max_net_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_weekend = 'Y'
    GROUP BY 
        d.d_date_sk, d.d_year, d.d_month_seq
),
aggregated_sales AS (
    SELECT
        COALESCE(i.i_item_sk, 0) AS item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_value
    FROM 
        item i
    FULL OUTER JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    ds.d_year,
    ds.max_net_profit,
    COALESCE(as.total_sold, 0) AS total_sold_items,
    CASE 
        WHEN as.total_sales_value > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value_category
FROM 
    customer_summary cs
LEFT JOIN 
    date_summary ds ON cs.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_first_name = cs.c_first_name AND c.c_last_name = cs.c_last_name LIMIT 1)
LEFT JOIN 
    aggregated_sales as ON cs.c_customer_sk = as.item_sk
WHERE 
    cs.total_net_profit IS NOT NULL
    AND ds.max_net_profit IS NOT NULL
ORDER BY 
    cs.total_net_profit DESC,
    ds.max_net_profit DESC
LIMIT 100;
