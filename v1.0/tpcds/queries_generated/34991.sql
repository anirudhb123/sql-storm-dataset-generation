
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 365 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        s_item_sk,
        total_quantity,
        total_sales_price
    FROM 
        SalesCTE
    WHERE 
        rn <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
SalesAnalysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.hd_income_band_sk,
        COALESCE(ti.total_quantity, 0) AS total_quantity,
        ci.order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        TopItems ti ON ti.s_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk ORDER BY ws_sales_price DESC LIMIT 1)
)
SELECT 
    ca.ca_city,
    sa.cd_gender,
    COUNT(sa.c_customer_sk) AS customer_count,
    AVG(sa.total_quantity) AS avg_quantity,
    SUM(sa.order_count) AS total_orders,
    COUNT(DISTINCT CASE WHEN sa.hd_income_band_sk IS NULL THEN 1 END) AS null_income_band_count
FROM 
    SalesAnalysis sa
JOIN 
    customer_address ca ON sa.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city, sa.cd_gender
HAVING 
    COUNT(sa.c_customer_sk) > 5
ORDER BY 
    total_orders DESC, avg_quantity ASC;
