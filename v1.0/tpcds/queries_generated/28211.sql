
WITH CustomerCityCounts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
TopCities AS (
    SELECT 
        ca_city
    FROM 
        CustomerCityCounts
    ORDER BY 
        customer_count DESC
    LIMIT 5
),
ItemSalesInTopCities AS (
    SELECT 
        tca.ca_city,
        isi.i_item_id,
        isi.total_sales
    FROM 
        TopCities tca
    JOIN 
        customer_address ca ON ca.ca_city = tca.ca_city
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        ItemSales isi ON ss.ss_item_sk = isi.i_item_sk
)
SELECT 
    city,
    COUNT(DISTINCT item_id) AS unique_items_sold,
    SUM(total_sales) AS total_sales_volume
FROM 
    ItemSalesInTopCities
GROUP BY 
    city
ORDER BY 
    total_sales_volume DESC;
