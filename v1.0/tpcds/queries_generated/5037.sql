
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        w.w_warehouse_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, w.w_warehouse_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_state
)
SELECT 
    sd.web_site_id,
    sd.w_warehouse_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_state,
    cd.customer_count
FROM 
    SalesData sd
LEFT JOIN 
    CustomerDemographics cd ON sd.web_site_id LIKE 'A%' AND cd.customer_count > 100
ORDER BY 
    sd.total_sales DESC, cd.customer_count DESC;
