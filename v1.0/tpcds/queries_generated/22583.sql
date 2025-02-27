
WITH ranked_sales AS (
    SELECT 
        ws_cdemo_sk,
        SUM(ws_net_paid) AS total_spent,
        RANK() OVER (PARTITION BY ws_cdemo_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_cdemo_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, cd.cd_gender, cd.cd_marital_status
), 
store_returns_info AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        AVG(sr_return_amt) AS avg_return_amount,
        CASE 
            WHEN AVG(sr_return_amt) IS NULL THEN 'No Returns'
            WHEN AVG(sr_return_amt) > 50 THEN 'High Return'
            ELSE 'Low Return'
        END AS return_category
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
final_report AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.total_web_spent,
        s.total_returns,
        s.avg_return_amount,
        s.return_category,
        COALESCE(rs.total_spent, 0) AS ranked_spent
    FROM 
        customer_info ci
    LEFT JOIN 
        store_returns_info s ON ci.c_customer_sk = s.sr_customer_sk
    LEFT JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_cdemo_sk
    WHERE 
        ci.total_web_spent > 0
      AND 
        (ci.cd_gender = 'F' OR ci.cd_marital_status = 'S') 
      AND 
        (s.total_returns IS NULL OR s.total_returns < 5)
)
SELECT 
    c_customer_sk,
    c_first_name,
    c_last_name,
    total_web_spent,
    total_returns,
    avg_return_amount,
    return_category,
    RANK() OVER (ORDER BY total_web_spent DESC) as spending_rank
FROM 
    final_report
WHERE
    (total_web_spent > (SELECT AVG(total_web_spent) FROM final_report) OR total_returns IS NULL)
ORDER BY 
    spending_rank, c_last_name ASC;
