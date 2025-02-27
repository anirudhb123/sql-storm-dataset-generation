
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_sales,
        rn
    FROM SalesCTE
    WHERE rn <= 3
), RecentSales AS (
    SELECT
        RS.ws_item_sk,
        RS.total_sales,
        D.d_date AS sale_date
    FROM RankedSales RS
    JOIN date_dim D ON RS.ws_sold_date_sk = D.d_date_sk
), ItemCategories AS (
    SELECT 
        I.i_item_sk,
        I.i_category,
        SUM(RS.total_sales) AS category_sales
    FROM RecentSales RS
    JOIN item I ON RS.ws_item_sk = I.i_item_sk
    GROUP BY I.i_item_sk, I.i_category
)
SELECT 
    C.ca_city, 
    C.ca_state,
    IC.i_category,
    SUM(IC.category_sales) AS total_category_sales,
    COUNT(C.c_customer_sk) AS num_customers
FROM customer_address C
LEFT JOIN customer CU ON C.ca_address_sk = CU.c_current_addr_sk
LEFT JOIN ItemCategories IC ON CU.c_customer_sk = IC.ws_item_sk
WHERE 
    C.ca_state IS NOT NULL
    AND (C.ca_city LIKE '%Town%' OR C.ca_city IS NULL)
GROUP BY C.ca_city, C.ca_state, IC.i_category
HAVING SUM(IC.category_sales) > (SELECT AVG(total_sales) FROM RecentSales)
ORDER BY total_category_sales DESC;
