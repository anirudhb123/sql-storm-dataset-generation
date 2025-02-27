
WITH RECURSIVE CustomerReturns AS (
    SELECT wr_returning_customer_sk AS customer_sk, 
           SUM(wr_return_qty) AS total_returns,
           ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_qty) DESC) AS rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
MonthlySales AS (
    SELECT d.d_year, d.d_month_seq, 
           SUM(ws_ext_sales_price) AS total_sales, 
           SUM(ws_quantity) AS total_quantity,
           AVG(ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
TopStores AS (
    SELECT s.s_store_sk, s.s_store_id, 
           SUM(ss_ext_sales_price) AS total_store_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_id
    ORDER BY total_store_sales DESC
    LIMIT 5
)
SELECT ca.ca_city, 
       COUNT(DISTINCT c.c_customer_sk) AS number_of_customers,
       COALESCE(SUM(cr_total_returns.total_returns), 0) AS total_customer_returns,
       ms.total_sales,
       ms.total_quantity,
       ms.avg_net_paid,
       ts.total_store_sales
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN CustomerReturns cr_total_returns ON cr_total_returns.customer_sk = c.c_customer_sk
JOIN MonthlySales ms ON ms.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
                    AND ms.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)
JOIN TopStores ts ON ts.s_store_sk = c.c_current_hdemo_sk
WHERE ca.ca_state = 'CA'
AND c.c_current_cdemo_sk IS NOT NULL
GROUP BY ca.ca_city, ms.total_sales, ms.total_quantity, ms.avg_net_paid, ts.total_store_sales
ORDER BY total_customer_returns DESC
LIMIT 10;
