
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           1 AS depth,
           NULL::integer AS parent_customer_sk
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.depth + 1,
           ch.c_customer_sk
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
),
CustomerAddresses AS (
    SELECT ca.*, ch.c_first_name, ch.c_last_name, ch.depth
    FROM customer_address ca
    JOIN CustomerHierarchy ch ON ca.ca_address_sk = ch.c_current_addr_sk
),
SalesData AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_net_paid,
           date_dim.d_year, date_dim.d_month_seq,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    JOIN date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
),
FilteredSales AS (
    SELECT sd.* 
    FROM SalesData sd
    WHERE sd.rn = 1 AND sd.ws_net_paid > 100.00
),
AggregatedSales AS (
    SELECT f.d_year, f.d_month_seq, SUM(f.ws_net_paid) AS total_sales
    FROM FilteredSales f
    GROUP BY f.d_year, f.d_month_seq
),
ShippingModes AS (
    SELECT sm.sm_ship_mode_sk, sm.sm_carrier,
           CASE 
               WHEN sm.sm_carrier IS NULL THEN 'Unknown'
               WHEN sm.sm_carrier LIKE '%Express%' THEN 'Express'
               ELSE 'Standard'
           END AS ship_category
    FROM ship_mode sm
),
FinalResults AS (
    SELECT ca.ca_city, SUM(as.total_sales) AS sales_total,
           COUNT(DISTINCT ca.c_first_name || ' ' || ca.c_last_name) AS customer_count,
           MAX(sm.ship_category) AS shipping_category
    FROM CustomerAddresses ca
    LEFT JOIN AggregatedSales as ON ca.depth = as.d_year % 10
    LEFT JOIN ShippingModes sm ON sm.sm_ship_mode_sk = CASE 
                                                         WHEN ca.ca_city IS NOT NULL THEN 1
                                                         ELSE NULL 
                                                      END
    GROUP BY ca.ca_city
)
SELECT fr.*, 
       CASE 
           WHEN fr.sales_total IS NULL THEN 'No Sales'
           ELSE 'Sales Exist'
       END AS sales_status,
       CASE 
           WHEN fr.customer_count = 0 THEN 'No Customers'
           ELSE 'Customers Present'
       END AS customer_status
FROM FinalResults fr
WHERE fr.customer_count > 0
ORDER BY fr.sales_total DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
