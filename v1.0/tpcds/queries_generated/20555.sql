
WITH ranked_sales AS (
    SELECT 
        s_store_sk,
        s_store_id,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        DENSE_RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM 
        store_sales
    WHERE
        ss_sold_date_sk = CURRENT_DATE - INTERVAL '1' DAY  -- Sales from yesterday
    GROUP BY 
        s_store_sk, s_store_id
),
customer_analysis AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependencies
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year < 1980 
        AND cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c_customer_sk
),
sales_returns AS (
    SELECT 
        sr.returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns sr
    GROUP BY 
        sr.returning_customer_sk
)
SELECT 
    sa.s_store_id,
    sa.total_sales,
    ca.order_count,
    ca.total_profit,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(sr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sr.avg_return_quantity, 0) AS avg_return_quantity
FROM 
    ranked_sales sa
LEFT JOIN 
    customer_analysis ca ON sa.s_store_sk = ca.c_customer_sk
LEFT JOIN 
    sales_returns sr ON ca.c_customer_sk = sr.returning_customer_sk
WHERE 
    sa.rank <= 5
ORDER BY 
    total_sales DESC, total_profit DESC;
