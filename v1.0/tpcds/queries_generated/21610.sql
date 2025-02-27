
WITH RECURSIVE Income_Bands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk IS NOT NULL
), 
Customer_Info AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           cd.cd_gender, 
           cd.cd_marital_status,
           COUNT(DISTINCT CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_order_number END) AS sales_count,
           SUM(COALESCE(ws.ws_net_paid, 0)) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state IN ('CA', 'TX')
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), 
Sales_Rank AS (
    SELECT c.c_customer_id, 
           c.cd_gender, 
           c.cd_marital_status, 
           RANK() OVER (PARTITION BY c.cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM Customer_Info c
    WHERE c.sales_count > 5
), 
Promotion_Info AS (
    SELECT DISTINCT p.p_promo_name, 
           p.p_start_date_sk, 
           p.p_end_date_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y' AND 
          p.p_start_date_sk < (SELECT MAX(d.d_date_sk) 
                               FROM date_dim d WHERE d.d_year = 2023)
)
SELECT s.sales_rank, 
       ci.c_customer_id,
       ci.cd_gender,
       pi.p_promo_name,
       CASE 
           WHEN ci.total_sales >= 5000 THEN 'High Value'
           WHEN ci.total_sales BETWEEN 1000 AND 4999 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       COUNT(DISTINCT pi.p_promo_name) AS applicable_promotions
FROM Sales_Rank s
JOIN Customer_Info ci ON s.c_customer_id = ci.c_customer_id
LEFT JOIN Promotion_Info pi ON s.sales_rank <= 3
GROUP BY s.sales_rank, ci.c_customer_id, ci.cd_gender, pi.p_promo_name
HAVING COUNT(DISTINCT pi.p_promo_name) > 0 OR ci.cd_gender IS NULL
ORDER BY s.sales_rank, ci.c_customer_id;
