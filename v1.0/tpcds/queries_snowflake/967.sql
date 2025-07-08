
WITH AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(hd.hd_vehicle_count) AS total_vehicle_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
RankedSales AS (
    SELECT 
        d.d_date_id,
        s.total_sales,
        s.total_profit,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesData s
    JOIN 
        date_dim d ON s.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.customer_count,
    r.sales_rank,
    r.total_sales,
    r.total_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.avg_purchase_estimate,
    cd.total_vehicle_count
FROM 
    AddressInfo a
JOIN 
    RankedSales r ON a.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk LIMIT 1)
LEFT JOIN 
    CustomerDemographics cd ON a.customer_count > 0
WHERE 
    r.sales_rank <= 10
ORDER BY 
    a.ca_city, a.ca_state;
