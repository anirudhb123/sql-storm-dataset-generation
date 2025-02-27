
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_ship_mode_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ss.net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
FilteredCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.total_net_profit
    FROM 
        CustomerDetails cd
    WHERE 
        cd.total_net_profit > 1000 AND cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
),
FinalReport AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.ws_ship_mode_sk,
        SUM(ss.total_quantity) AS total_quantity_sold,
        SUM(ss.total_sales) AS total_sales_value,
        COUNT(DISTINCT fc.c_customer_sk) AS active_customers
    FROM 
        SalesSummary ss
    JOIN 
        FilteredCustomers fc ON ss.ws_sold_date_sk = fc.c_customer_sk
    GROUP BY 
        ss.ws_sold_date_sk, ss.ws_ship_mode_sk
)
SELECT 
    d.d_date AS sales_date,
    sm.sm_carrier AS shipping_method,
    fr.total_quantity_sold,
    fr.total_sales_value,
    fr.active_customers
FROM 
    FinalReport fr
JOIN 
    date_dim d ON d.d_date_sk = fr.ws_sold_date_sk
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = fr.ws_ship_mode_sk
WHERE 
    d.d_year = 2022
ORDER BY 
    d.d_date, shipping_method;
