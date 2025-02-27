
WITH RECURSIVE Customer_Tree AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ct.level + 1
    FROM customer c
    JOIN Customer_Tree ct ON c.c_current_addr_sk = ct.c_customer_sk 
),
Sales_Data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk
),
Return_Data AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
Combined_Sales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_quantity_sold,
        sd.total_sales_price,
        rd.total_returns,
        rd.total_return_value,
        sd.total_sales_price - COALESCE(rd.total_return_value, 0) AS net_sales
    FROM Sales_Data sd
    LEFT JOIN Return_Data rd ON sd.ws_sold_date_sk = rd.sr_returned_date_sk
),
Final_Report AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity_sold,
        cs.total_sales_price,
        cs.net_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.total_sales_price DESC) AS rank
    FROM customer c
    LEFT JOIN Combined_Sales cs ON c.c_customer_sk = cs.ws_sold_date_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_quantity_sold,
    fr.total_sales_price,
    fr.net_sales,
    (CASE 
         WHEN fr.net_sales IS NULL THEN 'No Sales'
         WHEN fr.net_sales <= 0 THEN 'Loss'
         ELSE 'Profit'
     END) AS sales_status
FROM Final_Report fr
WHERE fr.rank = 1
ORDER BY fr.net_sales DESC;
