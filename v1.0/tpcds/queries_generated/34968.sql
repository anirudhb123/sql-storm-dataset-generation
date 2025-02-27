
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rn
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
CustomerStats AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY 
        c_customer_sk
),
ProductDemand AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        SUM(ws_quantity) AS total_web_sales,
        COALESCE(SUM(ss_quantity), 0) AS total_store_sales,
        COALESCE(SUM(cs_quantity), 0) AS total_catalog_sales,
        COUNT(DISTINCT ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss_ticket_number) AS store_order_count,
        COUNT(DISTINCT cs_order_number) AS catalog_order_count
    FROM 
        item
    LEFT JOIN 
        web_sales ON item.i_item_sk = ws_item_sk
    LEFT JOIN 
        store_sales ON item.i_item_sk = ss_item_sk
    LEFT JOIN 
        catalog_sales ON item.i_item_sk = cs_item_sk
    GROUP BY 
        item.i_item_sk, item.i_product_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(cs.total_net_profit) AS total_profit,
    AVG(pd.total_web_sales) AS avg_web_sales,
    MAX(pd.total_store_sales) AS max_store_sales,
    MIN(pd.total_catalog_sales) AS min_catalog_sales,
    CASE
        WHEN AVG(pd.total_web_sales) IS NULL THEN 'No sales data'
        ELSE 'Sales data available'
    END AS sales_availability
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    ProductDemand pd ON pd.i_item_sk IN (SELECT ts.ws_item_sk FROM web_sales ts WHERE ts.ws_bill_customer_sk = c.c_customer_sk)
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY 
    total_profit DESC, ca.ca_state;
