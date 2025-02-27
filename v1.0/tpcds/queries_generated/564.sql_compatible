
WITH Sales_Data AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_profit) AS avg_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020 AND dd.d_year <= 2023
    GROUP BY 
        ws.web_site_id
),
Customer_Demo AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.unique_customers,
    sd.avg_profit,
    cd.cd_gender,
    cd.ib_income_band_sk,
    CASE 
        WHEN cd.ib_income_band_sk IS NULL THEN 'Unknown Income Band'
        WHEN cd.ib_lower_bound < 20000 THEN 'Low Income'
        WHEN cd.ib_lower_bound BETWEEN 20000 AND 50000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_category
FROM 
    Sales_Data AS sd
LEFT JOIN 
    Customer_Demo AS cd ON sd.unique_customers = cd.cd_demo_sk
WHERE 
    sd.sales_rank <= 10
ORDER BY 
    sd.total_sales DESC;
