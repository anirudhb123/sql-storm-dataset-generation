
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, 
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS row_num
    FROM customer_address
    WHERE ca_state = 'CA' 
      AND ca_city IS NOT NULL
),
SalesCTE AS (
    SELECT ws_sold_date_sk, 
           SUM(ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk
),
ReturnStats AS (
    SELECT wr_item_sk,
           COUNT(*) AS total_returns,
           SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns
    GROUP BY wr_item_sk
),
DemographicCounts AS (
    SELECT cd_gender, 
           COUNT(DISTINCT c_customer_sk) AS customer_count, 
           SUM(cd_dep_count) AS total_dependencies,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
Combined AS (
    SELECT d.d_date_sk, 
           d.d_date_id, 
           ds.total_sales, 
           COALESCE(rs.total_returns, 0) AS total_returns,
           dc.customer_count,
           dc.avg_purchase_estimate
    FROM date_dim d 
    LEFT JOIN SalesCTE ds ON d.d_date_sk = ds.ws_sold_date_sk
    LEFT JOIN ReturnStats rs ON rs.wr_item_sk = (
        SELECT sr_item_sk FROM store_returns 
        WHERE sr_returned_date_sk = d.d_date_sk 
        LIMIT 1
    )
    LEFT JOIN DemographicCounts dc ON dc.cd_gender = 
        CASE 
            WHEN (d.d_dom % 2) = 0 THEN 'M' 
            ELSE 'F' 
        END
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT c.ca_city AS City,
       SUM(CASE WHEN b.total_sales IS NULL THEN 0 ELSE b.total_sales END) AS Total_Sales,
       AVG(b.avg_purchase_estimate) AS Average_Purchase_Estimate,
       SUM(b.total_returns) AS Total_Returns,
       COUNT(DISTINCT b.customer_count) AS Demographics_Count
FROM AddressCTE c
LEFT JOIN Combined b ON c.row_num = b.d_date_sk
GROUP BY c.ca_city
HAVING SUM(b.total_sales) > 10000
ORDER BY Total_Sales DESC
LIMIT 10;
