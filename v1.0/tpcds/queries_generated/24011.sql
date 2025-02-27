
WITH RECURSIVE CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spend,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_order_count,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_order_count,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spend,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        rd.d_current_year,
        ROW_NUMBER() OVER (PARTITION BY rd.d_current_year ORDER BY cs.total_spend DESC) AS yearly_rank
    FROM 
        CustomerSpend cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN 
        date_dim rd ON rd.d_date_sk = c.c_first_sales_date_sk
    WHERE 
        cs.total_spend IS NOT NULL AND cs.order_rank = 1
),
FinalReport AS (
    SELECT 
        tc.c_customer_id,
        tc.total_spend,
        tc.gender,
        tc.cd_marital_status,
        COALESCE(ib.ib_income_band_sk, 0) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY tc.gender ORDER BY tc.total_spend DESC) AS gender_spend_rank
    FROM 
        TopCustomers tc
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = tc.c_customer_sk
    LEFT JOIN 
        income_band ib ON ib.ib_upper_bound >= tc.total_spend AND ib.ib_lower_bound < tc.total_spend
)
SELECT 
    DISTINCT ON (fr.c_customer_id)
    fr.c_customer_id,
    fr.total_spend,
    fr.gender,
    fr.cd_marital_status,
    fr.income_band,
    fr.gender_spend_rank
FROM 
    FinalReport fr
WHERE 
    fr.total_spend BETWEEN (SELECT MAX(total_spend) FROM FinalReport) * 0.1
    AND (SELECT MAX(total_spend) FROM FinalReport) * 0.5
ORDER BY 
    fr.gender, fr.total_spend DESC;
