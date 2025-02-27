
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_item_price,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
Demographic_Analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        COUNT(DISTINCT cs.order_count) AS total_orders
    FROM 
        Customer_Sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
Income_Band_Sales AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(CASE WHEN cs.total_sales > 1000 THEN 1 END) AS affluent_customers,
        SUM(cs.total_sales) AS total_income_band_sales
    FROM 
        Customer_Sales cs
    JOIN 
        household_demographics hd ON cs.c_customer_id = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    ibs.affluent_customers,
    da.avg_sales,
    ibs.total_income_band_sales,
    CASE 
        WHEN da.avg_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    Demographic_Analysis da
LEFT JOIN 
    Income_Band_Sales ibs ON 1=1
WHERE 
    da.customer_count > 10 AND 
    (da.cd_gender = 'F' OR da.cd_marital_status = 'S')
ORDER BY 
    da.avg_sales DESC;
