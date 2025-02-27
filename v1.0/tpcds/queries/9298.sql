
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
CustomerWithDemographics AS (
    SELECT 
        ss.c_customer_id,
        ss.total_quantity,
        ss.total_spent,
        ss.order_count,
        ss.last_purchase_date,
        d.cd_gender,
        d.cd_marital_status,
        d.ib_lower_bound,
        d.ib_upper_bound
    FROM 
        SalesSummary ss
    LEFT JOIN 
        Demographics d ON ss.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = d.cd_demo_sk)
)
SELECT 
    cwd.c_customer_id,
    cwd.total_quantity,
    cwd.total_spent,
    cwd.order_count,
    cwd.last_purchase_date,
    cwd.cd_gender,
    cwd.cd_marital_status,
    CASE 
        WHEN cwd.total_spent < cwd.ib_lower_bound THEN 'Below Income Threshold'
        WHEN cwd.total_spent BETWEEN cwd.ib_lower_bound AND cwd.ib_upper_bound THEN 'Within Income Band'
        ELSE 'Above Income Threshold'
    END AS income_status
FROM 
    CustomerWithDemographics cwd
ORDER BY 
    cwd.total_spent DESC
LIMIT 20;
