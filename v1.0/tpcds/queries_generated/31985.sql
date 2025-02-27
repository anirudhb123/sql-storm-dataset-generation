
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           ca_state,
           cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY cd_purchase_estimate DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesCTE AS (
    SELECT ws.web_site_sk,
           SUM(ws.ws_ext_sales_price) AS Total_Sales,
           COUNT(DISTINCT ws.ws_order_number) AS Orders_Count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_sk
),
FilteredSales AS (
    SELECT ss_store_sk,
           SUM(ss_ext_sales_price) AS Store_Sales,
           COUNT(DISTINCT ss_ticket_number) AS Store_Orders
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk
)
SELECT ccte.c_first_name,
       ccte.c_last_name,
       ccte.ca_state,
       COALESCE(sales.Total_Sales, 0) AS Total_Web_Sales,
       COALESCE(fs.Store_Sales, 0) AS Total_Store_Sales,
       (COALESCE(sales.Total_Sales, 0) + COALESCE(fs.Store_Sales, 0)) AS Combined_Sales
FROM CustomerCTE ccte
LEFT JOIN SalesCTE sales ON ccte.c_customer_sk = sales.web_site_sk
LEFT JOIN FilteredSales fs ON ccte.c_current_addr_sk = fs.ss_store_sk
WHERE ccte.rnk <= 10
ORDER BY Combined_Sales DESC;
