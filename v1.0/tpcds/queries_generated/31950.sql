
WITH RECURSIVE SalesHierarchy AS (
    SELECT ss_item_sk, ss_sales_price, ss_quantity, 1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT max(ss_sold_date_sk) FROM store_sales)
    UNION ALL
    SELECT ss.item_sk, ss.ss_sales_price, ss.ss_quantity, sh.level + 1
    FROM store_sales ss
    JOIN SalesHierarchy sh ON ss.ss_item_sk = sh.ss_item_sk AND sh.level < 5
),
SalesAggregates AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COUNT(DISTINCT ss_ticket_number) AS total_sales_transactions,
        SUM(ss_sales_price * ss_quantity) AS total_sales_amount,
        AVG(ss_sales_price) AS average_sales_price,
        RANK() OVER (ORDER BY SUM(ss_sales_price * ss_quantity) DESC) AS sales_rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY i.i_item_id, i.i_item_desc
),
CustomerReturnStatistics AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns wr
    JOIN customer c ON wr_returning_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    sa.i_item_id,
    sa.i_item_desc,
    sa.total_sales_transactions,
    sa.total_sales_amount,
    sa.average_sales_price,
    cr.total_web_returns,
    CR.total_return_amount,
    COALESCE(cr.total_web_returns, 0) as adjusted_returns,
    CASE 
        WHEN sa.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular'
    END as seller_category
FROM SalesAggregates sa
LEFT JOIN CustomerReturnStatistics cr ON sa.i_item_id = cr.c_customer_id
WHERE sa.average_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales ws WHERE ws.ws_sold_date_sk IS NOT NULL)
ORDER BY sa.total_sales_amount DESC
LIMIT 100;
