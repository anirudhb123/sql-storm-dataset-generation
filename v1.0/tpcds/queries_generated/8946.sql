
WITH CustomerPriorities AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
TopCustomers AS (
    SELECT 
        c.*,
        p.*,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        CustomerPriorities c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        rank = 1
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd_gender, cd_marital_status, cd_education_status, 
        cd_purchase_estimate, cd_credit_rating, cd_dep_count, hd_income_band_sk, hd_buy_potential, 
        p.p_promo_sk, p.p_promo_name
),
SalesByType AS (
    SELECT 
        'Web Sales' AS sales_type, 
        SUM(ws.ws_net_profit) AS total_profit 
    FROM 
        web_sales ws
    UNION ALL
    SELECT 
        'Store Sales' AS sales_type, 
        SUM(ss.ss_net_profit) AS total_profit 
    FROM 
        store_sales ss
    UNION ALL
    SELECT 
        'Catalog Sales' AS sales_type, 
        SUM(cs.cs_net_profit) AS total_profit 
    FROM 
        catalog_sales cs
)
SELECT 
    t.total_profit, 
    s.sales_type, 
    COUNT(DISTINCT c.c_customer_id) AS customer_count
FROM 
    TopCustomers t
JOIN 
    SalesByType s ON t.total_profit > s.total_profit
GROUP BY 
    t.total_profit, s.sales_type
ORDER BY 
    t.total_profit DESC, 
    customer_count DESC;
