
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        RankedSales cs
    WHERE 
        cs.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
),
SalesWithDemographics AS (
    SELECT 
        hs.c_customer_id,
        hs.total_sales,
        hs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country
    FROM 
        HighSpenders hs
    JOIN 
        CustomerDemographics cd ON hs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    coalesce(cd.ca_city, 'Unknown') AS city,
    cd.ca_state AS state,
    cd.ca_country AS country,
    SUM(sw.total_sales) AS total_sales,
    AVG(sw.order_count) AS avg_orders,
    COUNT(*) AS customer_count
FROM 
    SalesWithDemographics sw
JOIN 
    customer_address cd ON sw.c_customer_id = cd.ca_address_sk
GROUP BY 
    cd.ca_city, cd.ca_state, cd.ca_country
HAVING 
    SUM(sw.total_sales) > 50000
ORDER BY 
    total_sales DESC
LIMIT 20;
