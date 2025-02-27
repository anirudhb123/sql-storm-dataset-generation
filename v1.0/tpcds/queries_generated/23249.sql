
WITH demographic_analysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sale_price,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_sales
    FROM 
        customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > (SELECT AVG(cd_inner.cd_purchase_estimate) FROM customer_demographics cd_inner)
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
high_value_customers AS (
    SELECT 
        da.cd_demo_sk,
        da.cd_gender,
        da.cd_marital_status,
        da.cd_education_status,
        da.cd_purchase_estimate,
        da.total_quantity,
        da.avg_sale_price,
        da.total_orders
    FROM 
        demographic_analysis da
    WHERE 
        da.total_quantity > 50 AND
        (da.cd_marital_status = 'M' OR da.cd_gender = 'F')
)
SELECT 
    hvc.cd_demo_sk,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.total_quantity,
    hvc.avg_sale_price,
    hvc.total_orders,
    CASE 
        WHEN hvc.total_orders > 10 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_type,
    COALESCE((
        SELECT COUNT(*) 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk = hvc.cd_demo_sk)
        AND ss.ss_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE)
    ), 0) AS recent_store_sales,
    LEAD(hvc.avg_sale_price) OVER (ORDER BY hvc.total_quantity DESC) AS next_avg_sale_price
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_quantity DESC, 
    hvc.avg_sale_price ASC
LIMIT 100;
