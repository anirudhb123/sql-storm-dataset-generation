
WITH RECURSIVE IncomeHierarchy AS (
    SELECT hd_demo_sk, ib_income_band_sk, hd_buy_potential, hd_dep_count, hd_vehicle_count
    FROM household_demographics h
    JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    WHERE ib_lower_bound >= 0
    
    UNION ALL
    
    SELECT h.hd_demo_sk, i.ib_income_band_sk, h.hd_buy_potential, h.hd_dep_count + 1, h.hd_vehicle_count
    FROM household_demographics h
    JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    JOIN IncomeHierarchy ih ON h.hd_demo_sk = ih.hd_demo_sk
    WHERE ih.hd_dep_count < 5
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_billed_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amt,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_billed_date_sk, ws.ws_item_sk
),
AggregatedSales AS (
    SELECT 
        sd.ws_billed_date_sk,
        sd.ws_item_sk,
        sd.total_sold_quantity,
        sd.total_sales_amt,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.ws_billed_date_sk ORDER BY sd.total_sales_amt DESC) AS sales_rank
    FROM SalesData sd
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    c.c_first_name,
    c.c_last_name,
    SUM(cr.total_return_quantity) AS total_returned_quantity,
    SUM(cr.total_return_amt) AS total_returned_amt,
    SUM(a.total_sales_amt) AS total_sales,
    AVG(a.total_sales) AS avg_sales_per_purchase,
    ih.hd_buy_potential,
    ih.hd_dep_count,
    ih.hd_vehicle_count
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN AggregatedSales a ON a.ws_billed_date_sk = c.c_first_sales_date_sk
JOIN IncomeHierarchy ih ON c.c_current_hdemo_sk = ih.hd_demo_sk
WHERE ca.ca_state IS NOT NULL
  AND ca.ca_city LIKE '%Los%'
  AND ((cr.total_returned_quantity IS NULL AND cr.total_returned_amt IS NOT NULL) 
       OR (cr.total_returned_quantity IS NOT NULL AND cr.total_returned_amt IS NULL))
GROUP BY 
    ca.ca_city, ca.ca_state,
    c.c_first_name, c.c_last_name,
    ih.hd_buy_potential, ih.hd_dep_count, ih.hd_vehicle_count
HAVING COUNT(DISTINCT cr.total_returns) > 1
ORDER BY total_sales DESC;
