
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
), 
SalesByGender AS (
    SELECT 
        d.cd_gender, 
        SUM(cs.total_sales) AS total_sales_by_gender, 
        SUM(cs.total_orders) AS total_orders_by_gender
    FROM 
        CustomerSales cs
    JOIN 
        Demographics d ON cs.c_customer_id = d.cd_demo_sk
    GROUP BY 
        d.cd_gender
)
SELECT 
    sg.cd_gender,
    sg.total_sales_by_gender,
    sg.total_orders_by_gender,
    CASE 
        WHEN sg.total_sales_by_gender > 10000 THEN 'High Spender'
        WHEN sg.total_sales_by_gender BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    SalesByGender sg
ORDER BY 
    sg.total_sales_by_gender DESC;
