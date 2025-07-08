
WITH RECURSIVE IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1
    
    UNION ALL
    
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN IncomeBands ib_rec ON ib.ib_income_band_sk = ib_rec.ib_income_band_sk + 1
),
CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_paid) AS total_sales,
           LISTAGG(DISTINCT i.i_product_name, ', ') WITHIN GROUP (ORDER BY i.i_product_name) AS purchased_items
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopSales AS (
    SELECT c.*, 
           DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM CustomerSales c
)
SELECT cs.c_first_name,
       cs.c_last_name,
       CASE 
           WHEN cs.total_sales IS NULL THEN 'No Sales'
           WHEN cs.total_sales <= 1000 THEN 'Low Sales'
           WHEN cs.total_sales <= 5000 THEN 'Moderate Sales'
           ELSE 'High Sales'
       END AS sales_category,
       ib.ib_lower_bound, 
       ib.ib_upper_bound
FROM TopSales cs
LEFT JOIN IncomeBands ib ON cs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE cs.sales_rank <= 10
ORDER BY cs.total_sales DESC;
