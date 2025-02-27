
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
SalesByDemographics AS (
    SELECT 
        cs.cd_gender,
        COUNT(cs.c_customer_sk) AS customer_count,
        AVG(cs.total_spent) AS avg_spent
    FROM 
        CustomerStats cs
    GROUP BY 
        cs.cd_gender
)
SELECT 
    s.ws_item_sk,
    s.total_quantity,
    COALESCE(csd.customer_count, 0) AS total_customers,
    COALESCE(sbd.avg_spent, 0) AS avg_spent,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High Sales'
        WHEN s.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    SalesCTE s
LEFT JOIN 
    SalesByDemographics sbd ON s.total_quantity = sbd.customer_count
LEFT JOIN 
    (SELECT cd_gender, COUNT(c_customer_sk) AS customer_count FROM CustomerStats GROUP BY cd_gender) csd ON csd.cd_gender = 'M'
ORDER BY 
    s.total_sales DESC;
