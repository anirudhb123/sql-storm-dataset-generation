
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.purchase_count > 5
),
IncomeDemographics AS (
    SELECT 
        h.hd_income_band_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics h
    JOIN 
        customer_demographics cd ON h.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
)

SELECT 
    tc.c_customer_id AS customer_id,
    tc.total_spent,
    tc.rank,
    id.avg_purchase_estimate,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Purchases'
        ELSE CONCAT('$', ROUND(tc.total_spent, 2))
    END AS formatted_total_spent
FROM 
    TopCustomers tc
LEFT JOIN 
    IncomeDemographics id ON tc.rank <= 10 
    AND id.hd_income_band_sk = (
        SELECT hd_income_band_sk 
        FROM household_demographics 
        WHERE hd_demo_sk = (
            SELECT c.c_current_hdemo_sk 
            FROM customer c 
            WHERE c.c_customer_id = tc.c_customer_id
        )
        LIMIT 1
    )
WHERE 
    tc.total_spent > 1000
ORDER BY 
    tc.rank;
