
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE level < 5
),
SalesData AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss.ss_item_sk, ss.ss_ticket_number
),
RankedSales AS (
    SELECT 
        sd.ss_item_sk,
        sd.ss_ticket_number,
        sd.total_net_paid,
        sd.unique_customers,
        RANK() OVER (PARTITION BY sd.ss_item_sk ORDER BY sd.total_net_paid DESC) AS sales_rank
    FROM SalesData sd
),
AddressDetails AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE ca.ca_state IS NOT NULL
),
FinalReport AS (
    SELECT 
        ch.c_customer_sk,
        CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
        ad.ca_city,
        ad.ca_state,
        rs.ss_item_sk,
        rs.total_net_paid,
        rs.unique_customers,
        rs.sales_rank
    FROM CustomerHierarchy ch
    LEFT JOIN RankedSales rs ON ch.c_customer_sk = rs.ss_ticket_number
    LEFT JOIN AddressDetails ad ON ch.c_current_cdemo_sk = ad.ca_address_sk
)
SELECT 
    fr.full_name,
    fr.ca_city,
    fr.ca_state,
    SUM(fr.total_net_paid) AS total_sales,
    AVG(fr.unique_customers) AS avg_unique_customers,
    COUNT(*) AS transaction_count
FROM FinalReport fr
WHERE fr.ca_state IS NOT NULL
GROUP BY fr.full_name, fr.ca_city, fr.ca_state
HAVING SUM(fr.total_net_paid) > 1000
ORDER BY total_sales DESC, avg_unique_customers DESC;
