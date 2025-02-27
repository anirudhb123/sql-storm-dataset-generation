
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_sold_time_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity, 
        ws_ext_sales_price, 
        1 AS level 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231

    UNION ALL 

    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_sold_time_sk, 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_ext_sales_price, 
        s.level + 1 
    FROM 
        web_sales ws 
    JOIN 
        SalesCTE s ON ws.ws_item_sk = s.ws_item_sk 
    WHERE 
        s.level < 5
), 

AddressDetails AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ca_country 
    FROM 
        customer_address 
    WHERE 
        ca_country IS NOT NULL
), 

CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(CASE WHEN ss_item_sk IS NOT NULL THEN ss_net_profit ELSE 0 END) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_quantity) AS avg_quantity,
        MAX(ws_ext_sales_price) AS max_sales_price 
    FROM 
        customer c 
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk 
)

SELECT 
    c.c_customer_id,
    SUM(cs.total_sales) AS overall_sales,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    AVG(cs.avg_quantity) AS avg_order_quantity,
    COUNT(DISTINCT cs.order_count) AS unique_order_count,
    ROW_NUMBER() OVER (PARTITION BY ad.ca_city ORDER BY SUM(cs.total_sales) DESC) AS rank
FROM 
    CustomerSales cs 
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk 
LEFT JOIN 
    AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk 
GROUP BY 
    c.c_customer_id, ad.ca_city, ad.ca_state, ad.ca_country 
HAVING 
    overall_sales > 10000 
ORDER BY 
    overall_sales DESC;

