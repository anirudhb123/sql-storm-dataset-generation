
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        sd.cc_class,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5001 AND 15000 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_estimate_band
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ws.ws_ship_addr_sk = s.s_store_sk
    JOIN call_center cc ON s.s_store_sk = cc.cc_call_center_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN (SELECT DISTINCT cc_class FROM call_center) sd ON cc.cc_class = sd.cc_class
    WHERE d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk,
        sd.cc_class,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
)
SELECT 
    d.d_date, 
    SUM(total_sales) AS total_sales,
    SUM(order_count) AS total_orders,
    AVG(avg_net_profit) AS avg_net_profit,
    purchase_estimate_band,
    cc_class
FROM SalesData
JOIN date_dim d ON SalesData.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    d.d_date,
    purchase_estimate_band,
    cc_class
ORDER BY 
    d.d_date, 
    purchase_estimate_band DESC, 
    cc_class;
