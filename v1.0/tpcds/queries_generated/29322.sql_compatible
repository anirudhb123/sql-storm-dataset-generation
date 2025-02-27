
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address 
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
DateGroupedSales AS (
    SELECT 
        d.d_date AS sales_date,
        sd.total_sales,
        sd.order_count,
        sd.average_profit
    FROM 
        date_dim d
    JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
),
FinalBenchmark AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        dgs.sales_date,
        dgs.total_sales,
        dgs.order_count,
        dgs.average_profit,
        CASE 
            WHEN dgs.total_sales > 1000 THEN 'High Seller'
            WHEN dgs.total_sales BETWEEN 500 AND 1000 THEN 'Mid Seller'
            ELSE 'Low Seller'
        END AS sales_category
    FROM 
        CustomerDetails cd 
    JOIN 
        DateGroupedSales dgs ON cd.c_customer_sk = dgs.ws_item_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    sales_date,
    total_sales,
    order_count,
    average_profit,
    sales_category
FROM 
    FinalBenchmark
ORDER BY 
    sales_date DESC, total_sales DESC;
