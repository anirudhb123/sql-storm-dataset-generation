
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    UNION ALL
    SELECT 
        sr_customer_sk,
        SUM(sr_net_loss) AS total_profit,
        level + 1
    FROM 
        store_returns AS sr
    JOIN 
        SalesHierarchy AS sh ON sr_customer_sk = sh.customer_sk
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    c.c_customer_id,
    coalesce(ca.ca_city, 'Unknown') AS shipping_city,
    d.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    ch.total_profit,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY d.total_sales DESC) AS sales_rank
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    MonthlySales d ON d.d_year = 2023
LEFT JOIN 
    SalesHierarchy ch ON ch.customer_sk = c.c_customer_sk
WHERE 
    cd.cd_purchase_estimate >= 1000
    AND (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
    AND (ch.total_profit IS NULL OR ch.total_profit > 0)
ORDER BY 
    d.total_sales DESC, 
    ch.total_profit DESC
FETCH FIRST 100 ROWS ONLY;
