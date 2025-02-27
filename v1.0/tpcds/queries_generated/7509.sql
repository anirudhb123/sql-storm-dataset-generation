
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
Sales_Statistics AS (
    SELECT 
        total_sales,
        num_orders,
        AVG(total_sales) OVER () AS avg_sales,
        AVG(num_orders) OVER () AS avg_orders
    FROM 
        Customer_Sales
), 
Customer_Details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cs.total_sales,
        cs.num_orders,
        ss.s_store_name
    FROM 
        Customer_Sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating,
    cd.total_sales,
    cd.num_orders,
    cd.s_store_name,
    CASE 
        WHEN cd.total_sales > st.avg_sales THEN 'Above Average Sales'
        ELSE 'Below Average Sales'
    END AS sales_comparison
FROM 
    Customer_Details cd
JOIN 
    Sales_Statistics st ON cd.total_sales = st.total_sales
WHERE 
    cd.num_orders > 5
ORDER BY 
    cd.total_sales DESC
LIMIT 100;
