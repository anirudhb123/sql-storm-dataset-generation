
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_customer_sk
),
filtered_sales AS (
    SELECT 
        sd.ws_customer_sk,
        sd.total_net_profit,
        sd.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        sales_data sd
    JOIN 
        customer c ON sd.ws_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        sd.rank = 1 
        AND cd.cd_marital_status = 'M' 
        AND (cd.cd_gender = 'F' OR cd.cd_gender = 'M')
),
annual_sales AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        SUM(ws_ext_sales_price - ws_ext_tax) AS net_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    fs.ca_city,
    fs.ca_state,
    fs.total_net_profit,
    fs.order_count,
    CASE 
        WHEN fs.total_net_profit > (SELECT AVG(total_net_profit) FROM filtered_sales) THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS profit_comparison,
    COALESCE(aa.total_sales, 0) AS total_annual_sales,
    COALESCE(aa.total_tax, 0) AS total_annual_tax,
    COALESCE(aa.net_sales, 0) AS total_net_sales
FROM 
    filtered_sales fs
LEFT JOIN 
    annual_sales aa ON fs.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = fs.ca_city) 
ORDER BY 
    fs.total_net_profit DESC
LIMIT 100;
