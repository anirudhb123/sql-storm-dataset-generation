
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id, 
        SUM(ss_net_paid) AS total_spent, 
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        COUNT(DISTINCT ws_order_number) AS total_online_orders
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
IncomeDemographics AS (
    SELECT 
        h.hd_demo_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
    FROM 
        household_demographics h
    JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
),
HighSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        ID.ib_lower_bound,
        ID.ib_upper_bound
    FROM 
        CustomerStats cs
    JOIN 
        IncomeDemographics ID ON cs.c_customer_id = ID.hd_demo_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT 
    h.c_customer_id,
    h.total_spent,
    h.ib_lower_bound,
    h.ib_upper_bound,
    CASE 
        WHEN h.total_spent > ID.ib_upper_bound THEN 'High Income'
        WHEN h.total_spent < ID.ib_lower_bound THEN 'Low Income'
        ELSE 'Middle Income'
    END AS income_category
FROM 
    HighSpenders h
JOIN 
    IncomeDemographics ID ON h.c_customer_id = ID.hd_demo_sk
ORDER BY 
    h.total_spent DESC;
