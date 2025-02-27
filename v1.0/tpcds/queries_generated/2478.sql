
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        rn <= 10
),
TopCustomers AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        TopWebSites tw ON ws.ws_web_site_sk = tw.web_site_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerAggregation AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(tc.ws_bill_customer_sk) AS customer_count,
        SUM(tc.total_profit) AS total_profit
    FROM 
        customer_demographics cd
    LEFT JOIN 
        TopCustomers tc ON cd.cd_demo_sk = tc.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca.ca_city,
    cu.c_first_name,
    cu.c_last_name,
    COALESCE(ca.ca_state, 'Unknown') AS state,
    SUM(ca.ca_gmt_offset) AS total_gmt_offset,
    CASE 
        WHEN SUM(ca.ca_gmt_offset) > 0 THEN 'Positive Offset'
        WHEN SUM(ca.ca_gmt_offset) < 0 THEN 'Negative Offset'
        ELSE 'No Offset'
    END AS offset_description
FROM 
    customer cu
JOIN 
    customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
JOIN 
    CustomerAggregation cagg ON cagg.cd_gender = CASE WHEN cu.c_birth_month < 6 THEN 'M' ELSE 'F' END
GROUP BY 
    ca.ca_city, cu.c_first_name, cu.c_last_name, ca.ca_state
HAVING 
    COUNT(DISTINCT cu.c_customer_sk) > 5
ORDER BY 
    total_gmt_offset DESC;
