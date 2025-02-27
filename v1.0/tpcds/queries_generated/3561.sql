
WITH SalesSummary AS (
    SELECT 
        s_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_sales_price) AS average_price,
        MAX(ss_sales_price) AS max_price,
        MIN(ss_sales_price) AS min_price
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COALESCE(hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
StoreInfo AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        s.s_store_name,
        s.s_market_id,
        CASE 
            WHEN s.s_number_employees IS NULL THEN 'Not Available'
            ELSE CAST(s.s_number_employees AS CHAR)
        END AS employees_info
    FROM 
        warehouse w
    JOIN 
        store s ON w.w_warehouse_sk = s.s_store_sk
)
SELECT 
    si.s_store_name,
    si.w_warehouse_name,
    ss.total_sales,
    ss.total_net_profit,
    ss.average_price,
    ss.max_price,
    ss.min_price,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.income_band
FROM 
    SalesSummary ss
JOIN 
    StoreInfo si ON ss.s_store_sk = si.s_store_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.c_customer_sk IN (
        SELECT 
            c_customer_sk 
        FROM 
            customer 
        WHERE 
            c_current_addr_sk = si.w_warehouse_sk
    )
WHERE 
    ss.total_sales > 0
ORDER BY 
    ss.total_net_profit DESC
LIMIT 50;
