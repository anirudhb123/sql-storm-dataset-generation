
WITH RECURSIVE SalesCTE AS (
    SELECT ss_item_sk, SUM(ss_ext_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
    ) AND (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
    )
    GROUP BY ss_item_sk
    
    UNION ALL
    
    SELECT ss_item_sk, SUM(ss_ext_sales_price) AS total_sales, COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2024-01-01'
    ) AND (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2024-12-31'
    )
    GROUP BY ss_item_sk
),
TotalSales AS (
    SELECT item.i_item_sk, 
           item.i_item_desc, 
           COALESCE(SUM(SalesCTE.total_sales), 0) AS yearly_sales,
           COALESCE(SUM(SalesCTE.total_transactions), 0) AS total_units_sold,
           ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(SalesCTE.total_sales), 0) DESC) AS sales_rank
    FROM item
    LEFT JOIN SalesCTE ON item.i_item_sk = SalesCTE.ss_item_sk
    GROUP BY item.i_item_sk, item.i_item_desc
)
SELECT t.yearly_sales, 
       t.total_units_sold, 
       CONCAT(t.i_item_desc, ' (Rank: ', t.sales_rank, ')') AS item_details
FROM TotalSales t
WHERE t.yearly_sales > 10000
ORDER BY t.yearly_sales DESC
LIMIT 10;

SELECT DISTINCT
    ca_city, ca_state,
    SUM(ss_ext_sales_price) AS city_sales
FROM store_sales
JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN item ON store_sales.ss_item_sk = item.i_item_sk
WHERE item.i_current_price > 50.00
GROUP BY ca_city, ca_state
HAVING SUM(ss_ext_sales_price) IS NOT NULL
ORDER BY city_sales DESC;

EXCEPT

SELECT ca_city, ca_state
FROM customer_address
WHERE ca_country IS NULL;

SELECT
    COUNT(DISTINCT wr_returning_customer_sk) AS unique_returning_customers,
    AVG(wr_return_amt_inc_tax) AS avg_return_amount
FROM web_returns
WHERE wr_returning_customer_sk IS NOT NULL
AND wr_return_amt_inc_tax < 500
AND EXISTS (
    SELECT 1
    FROM web_sales
    WHERE wr_order_number = ws_order_number
    AND ws_net_profit > 0
);
