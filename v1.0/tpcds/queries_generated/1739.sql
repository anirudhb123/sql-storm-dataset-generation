
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        c_info.c_customer_sk,
        c_info.c_first_name,
        c_info.c_last_name,
        c_info.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer_info c_info
    LEFT JOIN 
        web_sales ws ON c_info.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c_info.rank <= 10
    GROUP BY 
        c_info.c_customer_sk, 
        c_info.c_first_name, 
        c_info.c_last_name,
        c_info.cd_gender
),
monthly_sales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS monthly_total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_month_seq
),
average_sales AS (
    SELECT 
        d.d_month_seq,
        AVG(monthly_total_sales) AS avg_sales
    FROM 
        monthly_sales
    GROUP BY 
        d_month_seq
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_spent,
    CASE 
        WHEN avg_sales.avg_sales IS NULL THEN 'N/A'
        ELSE (tc.total_spent - avg_sales.avg_sales) 
    END AS diff_from_avg_sales
FROM 
    top_customers tc
FULL OUTER JOIN 
    average_sales avg_sales ON tc.c_customer_sk = avg_sales.d_month_seq
WHERE 
    (tc.total_spent IS NOT NULL OR avg_sales.avg_sales IS NOT NULL)
ORDER BY 
    tc.total_spent DESC NULLS LAST;
