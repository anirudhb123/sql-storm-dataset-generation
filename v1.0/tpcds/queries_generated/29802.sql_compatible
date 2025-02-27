
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name, c.c_last_name) AS rn
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
DemoStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS max_credit_rating
    FROM 
        customer_demographics AS cd
    GROUP BY 
        cd.cd_gender
),
RecentPurchases AS (
    SELECT 
        ws.ws_ship_date_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim AS d)
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    rc.c_customer_id,
    rc.full_name,
    ds.total_customers,
    ds.avg_purchase_estimate,
    rp.total_sales,
    rp.total_revenue
FROM 
    RankedCustomers AS rc
JOIN 
    DemoStats AS ds ON rc.cd_gender = ds.cd_gender
LEFT JOIN 
    RecentPurchases AS rp ON rp.ws_ship_date_sk = rc.c_current_addr_sk
WHERE 
    rc.rn <= 10
ORDER BY 
    rc.cd_gender, rc.full_name;
