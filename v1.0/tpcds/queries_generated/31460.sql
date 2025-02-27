
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_brand, i_class, i_category, 1 AS level
    FROM item
    WHERE i_item_sk IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_brand, i.i_class, i.i_category, ih.level + 1
    FROM item AS i
    JOIN ItemHierarchy AS ih ON i.i_item_sk = ih.i_item_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_purchase_date,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) as sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT customer_sk, total_sales, order_count, last_purchase_date
    FROM SalesSummary
    WHERE sales_rank <= 10
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CASE 
            WHEN ca.ca_state IS NULL THEN 'Unknown'
            ELSE ca.ca_state
        END AS state_info
    FROM customer_address ca
)
SELECT 
    tc.customer_sk,
    ca.ca_city,
    ad.state_info,
    tc.total_sales,
    ROUND(RANK() OVER (ORDER BY tc.total_sales DESC) / (SELECT COUNT(*) FROM SalesSummary) * 100, 2) AS sales_percentile,
    STRING_AGG(DISTINCT ih.i_brand, ', ') AS item_brands
FROM TopCustomers tc
JOIN customer c ON tc.customer_sk = c.c_customer_sk
LEFT JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN ItemHierarchy ih ON c.c_current_hdemo_sk = ih.i_item_sk
GROUP BY tc.customer_sk, ca.ca_city, ad.state_info, tc.total_sales
HAVING SUM(tc.total_sales) > 1000 AND COUNT(ih.i_item_sk) > 2
ORDER BY tc.total_sales DESC;
