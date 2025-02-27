
WITH CustomerWithAddress AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_billed_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_billed_customer_sk
),
DemographicData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cwa.c_first_name,
    cwa.c_last_name,
    cwa.ca_city,
    cwa.ca_state,
    cwa.ca_country,
    sd.total_sales,
    sd.order_count,
    sd.last_purchase_date,
    dd.cd_gender,
    dd.cd_marital_status,
    dd.customer_count
FROM 
    CustomerWithAddress cwa
LEFT JOIN 
    SalesData sd ON cwa.c_customer_sk = sd.ws_billed_customer_sk
LEFT JOIN 
    DemographicData dd ON cwa.c_customer_sk = dd.cd_demo_sk
WHERE 
    sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC, cwa.c_last_name, cwa.c_first_name
LIMIT 50;
