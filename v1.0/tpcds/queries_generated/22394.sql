
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_ext_sales_price, 
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sale_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy BETWEEN 1 AND 6
    )
), 
TotalSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(*) AS num_sales 
    FROM web_sales 
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk, 
        COUNT(*) AS return_count, 
        SUM(wr_return_amt) AS return_amount
    FROM web_returns
    GROUP BY wr_item_sk
),
CombinedSales AS (
    SELECT 
        t.ws_item_sk, 
        t.total_sales, 
        t.num_sales, 
        COALESCE(r.return_count, 0) AS return_count, 
        COALESCE(r.return_amount, 0) AS return_amount
    FROM TotalSales t
    LEFT JOIN CustomerReturns r ON t.ws_item_sk = r.wr_item_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city, 
    SUM(cs.num_sales) AS total_sales_volume,
    AVG(cs.total_sales) AS avg_sales_per_item,
    MAX(CASE WHEN cs.return_count > 0 THEN 'Returned' ELSE 'Not Returned' END) AS return_status,
    COUNT(DISTINCT cs.ws_item_sk) AS unique_items_sold,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS products_sold,
    COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c.c_customer_id END) AS female_customers,
    COUNT(DISTINCT CASE WHEN DATE_PART('month', d.d_date) = 12 THEN c.c_customer_id END) AS customers_in_december
FROM CombinedSales cs
JOIN customer c ON c.c_customer_sk = cs.ws_item_sk
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN date_dim d ON d.d_date_sk = cs.ws_order_number % 1000 -- Obscure and bizarre way to simulate joining on date
WHERE cs.num_sales > 10 
  AND (ca.ca_state IS NULL OR ca.ca_state = 'NY' AND ca.ca_city NOT ILIKE '%town%')
GROUP BY c.c_customer_id, ca.ca_city
ORDER BY total_sales_volume DESC
LIMIT 100;
