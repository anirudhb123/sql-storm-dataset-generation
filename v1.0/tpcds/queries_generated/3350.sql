
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.web_name, ws_sold_date_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
SalesSummary AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
    HAVING 
        SUM(ws.ws_quantity) > 100
)
SELECT 
    R.web_name,
    R.ws_sold_date_sk,
    R.total_quantity,
    R.total_sales,
    H.c_first_name,
    H.c_last_name,
    H.cd_gender,
    H.cd_marital_status,
    S.d_date,
    S.total_quantity AS daily_sales_quantity,
    S.total_orders,
    S.total_profit
FROM 
    RankedSales R
LEFT JOIN 
    HighValueCustomers H ON R.web_site_sk = H.c_customer_sk
JOIN 
    SalesSummary S ON R.ws_sold_date_sk = S.d_date
WHERE 
    R.sales_rank = 1
    AND (H.cd_gender IS NULL OR H.cd_gender = 'F')
ORDER BY 
    R.total_sales DESC, S.total_profit DESC;
