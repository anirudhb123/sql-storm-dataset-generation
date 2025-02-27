
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS unique_ship_modes,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_credit_rating
    FROM 
        customer_demographics AS cd
    WHERE 
        cd.cd_purchase_estimate > 1000
    AND 
        cd.cd_gender = 'M'
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        income_band AS ib
)
SELECT 
    cs.c_customer_sk,
    ds.cd_gender,
    ds.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.total_sales,
    cs.order_count,
    cs.unique_ship_modes,
    cs.average_profit
FROM 
    CustomerSales AS cs
JOIN 
    Demographics AS ds ON cs.c_customer_sk = ds.cd_demo_sk
JOIN 
    IncomeBands AS ib ON ds.cd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    cs.total_sales DESC
LIMIT 100
OFFSET 0;
