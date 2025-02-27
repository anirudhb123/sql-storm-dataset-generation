
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit,
        ws.ws_bill_cdemo_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws.ws_bill_cdemo_sk
),
CustomerSales AS (
    SELECT 
        cd.c_customer_id,
        ss.total_sales,
        ss.order_count,
        ss.avg_profit
    FROM 
        CustomerDetails cd
    JOIN 
        SalesSummary ss ON cd.cd_demo_sk = ss.ws_bill_cdemo_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.avg_profit,
    CASE 
        WHEN cs.total_sales > 10000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CustomerSales cs
ORDER BY 
    cs.total_sales DESC
LIMIT 20;
