
WITH RECURSIVE SalesItemHierarchy AS (
    SELECT i_item_sk, 
           i_item_desc, 
           i_current_price, 
           NULL AS parent_id,
           1 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT si.i_item_sk, 
           si.i_item_desc, 
           si.i_current_price, 
           sh.i_item_sk AS parent_id,
           level + 1
    FROM item si
    JOIN SalesItemHierarchy sh ON si.i_item_sk = sh.i_item_sk
),
RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_order_number, ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk, 
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_returned_date_sk
)
SELECT 
    ca.ca_city,
    SUM(r.total_sales) AS total_sales_for_city,
    COALESCE(SUM(cr.total_returns), 0) AS total_returns_for_city,
    CASE 
        WHEN SUM(r.total_sales) > 0 
        THEN (SUM(cr.total_returns) * 1.0 / SUM(r.total_sales)) * 100 
        ELSE 0 
    END AS return_percentage,
    i.i_item_desc,
    i.i_current_price
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
LEFT JOIN CustomerReturns cr ON r.ws_order_number = cr.sr_returned_date_sk
JOIN item i ON r.ws_item_sk = i.i_item_sk
WHERE ca.ca_state = 'CA'
GROUP BY ca.ca_city, i.i_item_desc, i.i_current_price
ORDER BY total_sales_for_city DESC, return_percentage ASC;
