
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        DATE_TRUNC('month', d.d_date) AS sales_month,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        SUM(ws.ws_quantity) AS total_quantity,
        sm.sm_type AS shipping_mode
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_sold_date_sk, sales_month, shipping_mode
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_state, 
        ca.ca_zip, 
        SUM(sd.total_sales) AS state_sales_total
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ca.ca_state, ca.ca_zip
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.cd_demo_sk) AS customer_count,
    SUM(cd.state_sales_total) AS total_sales_by_demographics,
    AVG(cd.state_sales_total) AS avg_sales_by_demographics
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales_by_demographics DESC;
