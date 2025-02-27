
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity),
        SUM(cs_sales_price),
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS rn
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
customer_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM 
        item i
    LEFT JOIN 
        (SELECT 
            ws_item_sk, total_quantity, total_sales 
         FROM 
            sales_data) sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        customer_returns cr ON i.i_item_sk = cr.sr_item_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(iss.total_sales) AS total_sales_amount,
    AVG(iss.total_sales) AS average_sales,
    SUM(CASE WHEN iss.total_returns > 0 THEN iss.total_returns ELSE NULL END) AS total_returns,
    STRING_AGG(iss.i_item_desc, ', ') AS item_descriptions
FROM 
    item_summary iss
JOIN 
    customer c ON c.c_current_addr_sk IS NOT NULL
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10 AND
    SUM(iss.total_sales) > 1000 
ORDER BY 
    total_sales_amount DESC
LIMIT 5;
