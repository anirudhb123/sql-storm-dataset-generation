
WITH CustomerIncome AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
WebSalesAggregate AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerMetrics AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_marital_status,
        ci.cd_gender,
        ci.ib_lower_bound,
        ci.ib_upper_bound,
        COALESCE(wsa.total_orders, 0) AS total_orders,
        COALESCE(wsa.total_sales, 0) AS total_sales,
        COALESCE(wsa.total_profit, 0) AS total_profit
    FROM 
        CustomerIncome ci
        LEFT JOIN WebSalesAggregate wsa ON ci.c_customer_id = wsa.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ib_lower_bound,
    ib_upper_bound,
    total_orders,
    total_sales,
    total_profit,
    CASE 
        WHEN total_sales > 1000 THEN 'High Engagement'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Engagement'
        ELSE 'Low Engagement' 
    END AS engagement_level
FROM 
    CustomerMetrics
WHERE 
    ib_upper_bound > 50000
ORDER BY 
    total_sales DESC, total_orders DESC;
