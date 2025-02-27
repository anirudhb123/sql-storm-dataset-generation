
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws_order_number) AS purchase_count,
        SUM(ws.net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk, cd.cd_credit_rating
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ss.total_quantity,
    ss.total_sales,
    ss.order_count
FROM 
    CustomerInfo ci
JOIN 
    SalesSummary ss ON ci.purchase_count > 0
WHERE 
    ci.total_spent IS NOT NULL
    AND ci.cd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound > 50000)
    AND ci.c_last_name LIKE 'S%' 
ORDER BY 
    ss.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
