
WITH RECURSIVE CTE_Customer_Sales AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_net_profit) DESC) AS rnk
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
),
CTE_Income_Bands AS (
    SELECT 
        hd_income_band_sk,
        CASE 
            WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
        END AS income_range
    FROM 
        household_demographics
    JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
),
CTE_Customer_Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_birth_month,
        c.c_birth_year,
        cd.cd_dep_count,
        COALESCE(hd.hd_buy_potential, 'No Data') AS buy_potential,
        cdm.total_profit,
        cdm.order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CTE_Customer_Sales cdm ON c.c_customer_sk = cdm.cs_bill_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    cdem.c_customer_sk,
    cdem.cd_gender,
    cdem.cd_marital_status,
    cdem.c_birth_month,
    cdem.c_birth_year,
    cdem.buy_potential,
    ib.income_range,
    cdem.total_profit,
    cdem.order_count,
    RANK() OVER (ORDER BY cdem.total_profit DESC) AS profit_rank
FROM 
    CTE_Customer_Demographics cdem
LEFT JOIN 
    CTE_Income_Bands ib ON cdem.cd_dep_count < 10 -- Threshold for income band
WHERE 
    cdem.total_profit IS NOT NULL
ORDER BY 
    profit_rank
LIMIT 50;
