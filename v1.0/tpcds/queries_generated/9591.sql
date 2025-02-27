
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE 
        dd.d_year = 2023 AND 
        ca.ca_country = 'USA'
    GROUP BY 
        ws.web_site_id
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        cd.cd_gender
),
FinalReport AS (
    SELECT 
        s.web_site_id,
        s.total_sales,
        s.total_orders,
        s.average_profit,
        s.unique_customers,
        c.cd_gender,
        c.customer_count,
        c.average_purchase_estimate
    FROM 
        SalesData s
    LEFT JOIN 
        CustomerData c ON c.customer_count > 0
)
SELECT 
    web_site_id,
    total_sales,
    total_orders,
    average_profit,
    unique_customers,
    cd_gender,
    customer_count,
    average_purchase_estimate
FROM 
    FinalReport
ORDER BY 
    total_sales DESC
LIMIT 10;
