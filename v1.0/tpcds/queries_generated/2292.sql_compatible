
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk 
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        hs.c_customer_sk,
        hs.c_first_name,
        hs.c_last_name,
        hs.total_spent,
        hs.spend_rank,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        HighSpenders hs
    LEFT JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = hs.c_customer_sk)
    LEFT JOIN 
        income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    COALESCE(fr.total_spent, 0) AS total_spent,
    COALESCE(fr.spend_rank, 'Not Ranked') AS spend_rank,
    COALESCE(fr.cd_gender, 'Unknown') AS gender,
    COALESCE(fr.cd_marital_status, 'Unknown') AS marital_status,
    COALESCE(fr.ib_lower_bound, 0) AS lower_income_bound,
    COALESCE(fr.ib_upper_bound, 100000) AS upper_income_bound
FROM 
    FinalReport fr
WHERE 
    fr.spend_rank <= 10
ORDER BY 
    fr.total_spent DESC;
