
WITH RankedWebSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS demo_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        CustomerDetails cd
    JOIN 
        web_sales ws ON cd.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        cd.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > 1000
)
SELECT 
    w.web_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cv.c_customer_id) AS high_value_customers_count
FROM 
    web_site w
JOIN 
    web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
JOIN 
    HighValueCustomers cv ON ws.ws_bill_customer_sk = cv.c_customer_id
LEFT JOIN 
    RankedWebSales rws ON ws.ws_web_site_sk = rws.web_site_sk AND rws.sales_rank <= 10
WHERE 
    ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    w.web_name
ORDER BY 
    total_net_profit DESC;
