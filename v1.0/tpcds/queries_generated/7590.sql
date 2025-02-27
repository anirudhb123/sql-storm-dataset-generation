
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
SalesSummary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_id) AS customer_count,
        AVG(total_sales) AS avg_sales,
        SUM(total_sales) AS total_sales
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender
)
SELECT 
    ss.cd_gender,
    ss.customer_count,
    ss.avg_sales,
    ss.total_sales,
    rd.r_reason_desc AS promotional_reason,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS promotional_sales
FROM 
    SalesSummary ss
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = 'Seattle'))
LEFT JOIN 
    reason rd ON rd.r_reason_sk = (SELECT p.p_promo_sk FROM promotion p WHERE p.p_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_current_hdemo_sk IN (SELECT hd_demo_sk FROM household_demographics WHERE hd_income_band_sk = 1))))
GROUP BY 
    ss.cd_gender, rd.r_reason_desc
ORDER BY 
    total_sales DESC;
