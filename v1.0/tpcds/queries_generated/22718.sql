
WITH RECURSIVE Income_Bands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN Income_Bands ib2 ON ib.ib_income_band_sk = ib2.ib_income_band_sk + 1
),
Customer_Summary AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           d.d_year, 
           SUM(ws.ws_sales_price) AS total_sales,
           CASE 
               WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
               ELSE cd.cd_marital_status 
           END AS marital_status,
           RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_sales_price) DESC) as sales_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
Ranked_Customers AS (
    SELECT *,
           CASE 
               WHEN sales_rank <= 10 THEN 'Top 10'
               ELSE 'Others'
           END AS customer_category
    FROM Customer_Summary
)
SELECT cc.c_customer_id,
       ca.ca_address_id,
       ra.total_sales,
       ra.marital_status,
       COALESCE(ib.ib_lower_bound, 0) AS income_lower,
       COALESCE(ib.ib_upper_bound, 0) AS income_upper,
       ra.customer_category
FROM Ranked_Customers ra
JOIN customer c ON ra.c_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN Income_Bands ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ra.total_sales IS NOT NULL
  AND ra.marital_status IN ('S', 'M', 'D')
  AND (ra.total_sales BETWEEN 1000 AND 5000 OR ra.customer_category = 'Top 10')
ORDER BY ra.total_sales DESC, ra.marital_status ASC
LIMIT 20 OFFSET 5;
