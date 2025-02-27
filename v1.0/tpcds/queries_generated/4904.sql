
WITH RevenueData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_cdemo_sk
), 
HighSpendingCustomers AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        rd.total_revenue,
        rd.order_count,
        RANK() OVER (ORDER BY rd.total_revenue DESC) AS revenue_rank
    FROM 
        customer_demographics cd 
    LEFT JOIN 
        RevenueData rd ON cd.cd_demo_sk = rd.ws_bill_cdemo_sk
    WHERE 
        (cd_income_band_sk IS NOT NULL) AND 
        (cd_gender = 'F' OR cd_marital_status = 'M')
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        h.hd_income_band_sk,
        h.hd_buy_potential,
        h.hd_dep_count,
        h.hd_vehicle_count
    FROM 
        customer c 
    JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
)
SELECT 
    cds.c_customer_id,
    cds.c_first_name,
    cds.c_last_name,
    hsc.cd_gender,
    hsc.cd_marital_status,
    hsc.total_revenue,
    hsc.order_count,
    CASE 
        WHEN hsc.total_revenue IS NULL THEN 'No Purchases' 
        WHEN hsc.total_revenue > 10000 THEN 'High Value' 
        ELSE 'Regular'
    END AS customer_category
FROM 
    CustomerDetails cds
LEFT JOIN 
    HighSpendingCustomers hsc ON cds.c_current_cdemo_sk = hsc.cd_demo_sk
WHERE 
    hsc.revenue_rank <= 10 OR hsc.revenue_rank IS NULL
ORDER BY 
    cds.c_last_name, 
    cds.c_first_name;
