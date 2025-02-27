
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        MIN(ws.ws_sold_date_sk) AS first_purchase_date,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_id
), 
Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        ib.ib_income_band_sk
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ds.total_sales,
    ds.total_orders,
    ds.avg_profit,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.ib_income_band_sk,
    (CASE 
        WHEN ds.total_sales > 10000 THEN 'High Value'
        WHEN ds.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_segment
FROM 
    SalesSummary AS ds
JOIN 
    Demographics AS d ON ds.c_customer_id = d.cd_demo_sk
WHERE 
    d.cd_gender = 'M' 
    AND d.cd_marital_status = 'S'
ORDER BY 
    ds.total_sales DESC
LIMIT 100;
