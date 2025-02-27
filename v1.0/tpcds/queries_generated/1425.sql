
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date AS first_purchase_date,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS purchase_rank,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
returns_info AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
final_report AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.first_purchase_date,
        ci.purchase_rank,
        ci.cd_marital_status,
        ci.cd_gender,
        ci.cd_purchase_estimate,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN ci.purchase_rank = 1 AND ci.cd_marital_status = 'M' THEN 'Married First-time Buyer'
            WHEN ci.purchase_rank = 1 AND ci.cd_marital_status = 'S' THEN 'Single First-time Buyer'
            ELSE 'Returning Customer'
        END AS customer_type
    FROM 
        customer_info ci
    LEFT JOIN 
        returns_info ri ON ci.c_customer_id = ri.sr_customer_sk
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.first_purchase_date,
    f.customer_type,
    COUNT(ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_profit) AS total_web_profit
FROM 
    final_report f
LEFT JOIN 
    web_sales ws ON f.c_customer_id = ws.ws_bill_customer_sk
WHERE 
    f.purchase_rank = 1 OR (f.total_returns > 0 AND f.customer_type = 'Returning Customer')
GROUP BY 
    f.c_customer_id, f.c_first_name, f.c_last_name, f.first_purchase_date, f.customer_type
ORDER BY 
    total_web_profit DESC
LIMIT 100;
