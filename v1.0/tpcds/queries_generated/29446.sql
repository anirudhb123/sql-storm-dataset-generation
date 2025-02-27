
WITH CustomerStats AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemStats AS (
    SELECT 
        i.i_item_id,
        LENGTH(i.i_item_desc) AS desc_length,
        i.i_current_price,
        i.i_brand,
        i.i_class,
        i.i_category
    FROM 
        item i
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        cs.cs_sales_price,
        ss.ss_sales_price
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
),
AggregatedSales AS (
    SELECT 
        COALESCE(ws.ws_order_number, cs.cs_order_number, ss.ss_ticket_number) AS order_id,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_sales_price, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_sales_price, 0)) AS total_store_sales
    FROM 
        SalesData
    GROUP BY 
        order_id
)
SELECT 
    cs.full_name,
    cs.ca_city,
    cs.ca_state,
    cs.ca_country,
    ROUND(AVG(CASE 
        WHEN ass.total_web_sales > 0 THEN ass.total_web_sales 
        ELSE NULL END), 2) AS avg_web_sales,
    ROUND(AVG(CASE 
        WHEN ass.total_catalog_sales > 0 THEN ass.total_catalog_sales 
        ELSE NULL END), 2) AS avg_catalog_sales,
    ROUND(AVG(CASE 
        WHEN ass.total_store_sales > 0 THEN ass.total_store_sales 
        ELSE NULL END), 2) AS avg_store_sales
FROM 
    CustomerStats cs
LEFT JOIN 
    AggregatedSales ass ON cs.full_name LIKE '%' || ass.order_id || '%'
GROUP BY 
    cs.full_name, cs.ca_city, cs.ca_state, cs.ca_country
ORDER BY 
    avg_web_sales DESC, avg_catalog_sales DESC, avg_store_sales DESC;
