
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        WS.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(s.ws_ext_sales_price), 0) AS TotalWebSales,
    COALESCE(SUM(st.ss_ext_sales_price), 0) AS TotalStoreSales,
    (SELECT 
         COUNT(*) 
     FROM 
         store_sales st 
     WHERE 
         st.ss_customer_sk = c.c_customer_sk) AS StorePurchaseCount,
    d.d_year,
    d.d_month_seq
FROM 
    customer c
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    store_sales st ON c.c_customer_sk = st.ss_customer_sk 
LEFT JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk
WHERE 
    (d.d_year = 2023 OR d.d_year IS NULL)
    AND c.c_current_cdemo_sk IS NOT NULL
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
HAVING 
    TotalWebSales > 1000
ORDER BY 
    TotalWebSales DESC
LIMIT 15;
