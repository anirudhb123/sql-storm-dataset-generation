
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY ss_item_sk
    UNION ALL
    SELECT 
        c.item_sk,
        SUM(c.ext_sales_price) + sh.total_sales,
        COUNT(c.ticket_number) + sh.total_transactions,
        RANK() OVER (PARTITION BY c.item_sk ORDER BY SUM(c.ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales c
    JOIN sales_hierarchy sh ON c.item_sk = sh.ss_item_sk
    WHERE sh.sales_rank <= 5
    GROUP BY c.item_sk
), 
item_info AS (
    SELECT
        i.i_item_id, 
        i.i_item_desc,
        ih.total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS ranked_sales
    FROM item i
    JOIN (SELECT 
              ss_item_sk, 
              SUM(ss_ext_sales_price) AS total_sales
          FROM store_sales
          WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450500
          GROUP BY ss_item_sk) AS sales_summary
    ON i.i_item_sk = sales_summary.ss_item_sk
), 
address_info AS (
    SELECT 
        ca_address_id,
        ca_city,
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_address_id, ca_city, ca_state
), 
sales_overview AS (
    SELECT 
        bb.total_sales, 
        ii.i_item_desc,
        aa.ca_city,
        aa.ca_state
    FROM item_info ii
    JOIN sales_hierarchy bb ON ii.i_item_id = bb.ss_item_sk 
    JOIN address_info aa ON ii.ranked_sales = 1
) 
SELECT 
    city,
    state,
    SUM(total_sales) AS total_sales_by_city,
    COUNT(DISTINCT i_item_id) AS total_items_sold
FROM sales_overview
GROUP BY city, state
ORDER BY total_sales_by_city DESC
HAVING COUNT(DISTINCT i_item_id) > 2
   AND SUM(total_sales) > 1000.00;
