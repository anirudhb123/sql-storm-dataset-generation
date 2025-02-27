
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE 
            WHEN SUM(ws.ws_ext_sales_price) IS NULL THEN 'No Sales'
            ELSE 'Sales Made'
        END AS sales_status
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopSellers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_quantity,
        cs.total_sales,
        ca.ca_city,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer_address AS ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cs.c_customer_sk)
    WHERE 
        cs.total_sales > 0
)
SELECT 
    t.customer_name,
    t.total_sales,
    COALESCE(s.total_profit, 0) AS total_profit,
    t.ca_city,
    t.sales_rank
FROM 
    (SELECT 
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        cs.total_sales,
        cs.total_quantity,
        ca.ca_city
    FROM 
        CustomerSales cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cs.total_sales IS NOT NULL) AS t
LEFT JOIN 
    SalesCTE s ON s.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_item_desc LIKE '%widget%' AND i.i_current_price > 10)
WHERE 
    t.total_sales > 1000
ORDER BY 
    total_profit DESC, sales_rank ASC
LIMIT 50;
