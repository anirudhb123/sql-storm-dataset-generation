
WITH CustomerConcat AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    JOIN 
        CustomerConcat cc ON ws.ws_ship_customer_sk = cc.c_customer_sk
    GROUP BY 
        ws.web_site_id
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_sales_quantity,
        total_net_paid,
        RANK() OVER (ORDER BY total_net_paid DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.total_sales_quantity,
    r.total_net_paid,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
