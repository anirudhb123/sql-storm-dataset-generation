
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
DateAnalysis AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS yearly_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    da.yearly_sales,
    da.total_orders,
    CASE 
        WHEN hs.spend_rank <= 10 THEN 'Top 10 Spenders'
        ELSE 'Other'
    END AS spender_category
FROM 
    HighSpenders hs
JOIN DateAnalysis da ON da.yearly_sales > 100000
WHERE 
    EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk IN (SELECT DISTINCT ws.ws_store_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = hs.c_customer_sk)
    )
ORDER BY 
    hs.total_spent DESC, hs.c_last_name ASC;
