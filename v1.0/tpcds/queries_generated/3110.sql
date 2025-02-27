
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL 
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
RankedCustomers AS (
    SELECT 
        customer_id,
        cd_gender,
        cd_marital_status,
        total_orders,
        total_spent,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS order_rank
    FROM CustomerSales
),
IncomeDistribution AS (
    SELECT 
        cd.cd_income_band_sk,
        COUNT(c.c_customer_id) AS customer_count,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY cd_income_band_sk
)
SELECT 
    rc.customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_orders,
    rc.total_spent,
    CASE 
        WHEN rc.order_rank <= 10 THEN 'Top Tier'
        WHEN rc.order_rank <= 50 THEN 'Mid Tier'
        ELSE 'Budget Tier'
    END AS customer_tier,
    id.total_revenue / NULLIF(id.customer_count, 0) AS avg_revenue_per_customer
FROM RankedCustomers rc
JOIN IncomeDistribution id ON rc.total_orders > 0
WHERE rc.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
ORDER BY rc.total_spent DESC
LIMIT 100;
