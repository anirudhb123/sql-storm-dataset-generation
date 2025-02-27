
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk < 1000  -- Base case for recursion
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE c.c_customer_sk <> ch.c_customer_sk AND ch.level < 5 -- Limiting recursion to 5 levels
),
AggregateSales AS (
    SELECT 
        ws.ws_ship_mode_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    JOIN CustomerHierarchy ch ON ws.ws_ship_customer_sk = ch.c_customer_sk
    GROUP BY ws.ws_ship_mode_sk
),
SalesWithDemographics AS (
    SELECT 
        cs.cs_order_number,
        cd.cd_gender,
        cd.cd_marital_status,
        asales.total_orders,
        asales.total_sales,
        asales.avg_profit
    FROM catalog_sales cs
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN AggregateSales asales ON cs.cs_promo_sk = asales.ws_ship_mode_sk
)
SELECT 
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales Data'
        ELSE CONCAT('Total Sales: ', total_sales)
    END AS sales_status,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(sales_with_demographics.cs_order_number) AS order_count,
    SUM(sales_with_demographics.total_sales) AS sales_amount,
    COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
    COUNT(DISTINCT CASE WHEN ch.c_first_name IS NOT NULL THEN ch.c_customer_sk END) AS active_customers
FROM SalesWithDemographics sales_with_demographics
JOIN CustomerHierarchy ch ON sales_with_demographics.cs_order_number = ch.c_customer_sk
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING COUNT(sales_with_demographics.cs_order_number) > 10
ORDER BY sales_amount DESC;
