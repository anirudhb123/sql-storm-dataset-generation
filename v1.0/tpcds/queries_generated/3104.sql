
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws.ws_quantity) AS total_quantity,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
high_value_customers AS (
    SELECT 
        c.customer_sk,
        c.total_quantity,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS sales_rank
    FROM 
        customer_summary AS c
    WHERE 
        c.total_spent > 1000
),
recent_period AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_date
    FROM 
        date_dim AS d
    WHERE 
        d.d_date > CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_purchase_estimate,
    r.total_quantity,
    r.total_spent,
    hp.sales_rank,
    CASE 
        WHEN hp.total_spent IS NULL THEN 'No Sales'
        ELSE 'High Value Customer'
    END AS customer_status,
    COALESCE(t.total_transactions, 0) AS total_transactions,
    COALESCE(NULLIF(total_spent, 0), 'Unknown') AS spent_or_status
FROM 
    customer_summary AS r
LEFT JOIN 
    high_value_customers AS hp ON r.c_customer_sk = hp.customer_sk
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_transactions
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM recent_period)
    GROUP BY 
        ws_bill_customer_sk
) AS t ON r.c_customer_sk = t.ws_bill_customer_sk
ORDER BY 
    r.total_spent DESC, 
    r.c_last_name ASC 
FETCH FIRST 100 ROWS ONLY;
