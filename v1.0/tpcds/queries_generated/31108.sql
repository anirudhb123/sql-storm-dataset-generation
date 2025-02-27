
WITH RECURSIVE sales_growth AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_sales,
        0 AS year_difference
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        D.d_date_sk,
        COALESCE(S.total_sales, 0) AS total_sales,
        D.d_year - YEAR(DATE_SUB(CURDATE(), INTERVAL 1 YEAR)) AS year_difference
    FROM 
        date_dim D
    LEFT JOIN 
        sales_growth S ON D.d_date_sk = DATE_ADD(S.ws_sold_date_sk, INTERVAL 1 YEAR)
    WHERE 
        D.d_year <= YEAR(CURDATE())
),
filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_credit_rating IN ('High', 'Medium')
),
sales_data AS (
    SELECT 
        WS.ws_web_site_sk, 
        SUM(WS.ws_net_profit) AS total_net_profit,
        COUNT(WS.ws_order_number) AS total_orders
    FROM 
        web_sales WS
    GROUP BY 
        WS.ws_web_site_sk
)
SELECT 
    CA.ca_city,
    SUM(SG.total_sales) AS sales_growth,
    COALESCE(FC.c_first_name, 'N/A') AS customer_first_name,
    COALESCE(FC.c_last_name, 'N/A') AS customer_last_name,
    COALESCE(FC.cd_gender, 'N/A') AS customer_gender,
    COALESCE(SD.total_net_profit, 0) AS total_net_profit,
    COUNT(DISTINCT SD.total_orders) AS distinct_orders
FROM 
    sales_growth SG
LEFT JOIN 
    store_sales SS ON SG.ws_sold_date_sk = SS.ss_sold_date_sk
LEFT JOIN 
    customer_address CA ON SS.ss_addr_sk = CA.ca_address_sk
LEFT JOIN 
    filtered_customers FC ON SG.ws_sold_date_sk = FC.c_customer_sk
LEFT JOIN 
    sales_data SD ON CA.ca_state = (SELECT MAX(CA.ca_state) FROM customer_address CA GROUP BY CA.ca_state)
WHERE 
    SG.year_difference BETWEEN 0 AND 1
GROUP BY 
    CA.ca_city, FC.c_first_name, FC.c_last_name, FC.cd_gender, SD.total_net_profit
ORDER BY 
    sales_growth DESC, total_net_profit DESC
LIMIT 100;
