
WITH RECURSIVE IncomeTrend (income_band, total_sales, rank) AS (
    SELECT ib.income_band_sk, SUM(ws.ws_net_paid) AS total_sales,
           RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM income_band ib 
    JOIN customer_demographics cd ON cd.cd_demo_sk = ib.ib_income_band_sk
    LEFT JOIN web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk 
    GROUP BY ib.income_band_sk
),
SalesReturn AS (
    SELECT wr.web_web_page_id, SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.web_web_page_id
),
SalesAggregate AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_net_paid) AS total_sales_value,
           COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    LEFT JOIN store_returns sr ON ws.ws_item_sk = sr.sr_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT c.c_customer_id, c.c_first_name, c.c_last_name,
       s.total_quantity_sold, s.total_sales_value, s.total_returns, s.total_profit,
       it.income_band, it.total_sales AS income_total_sales,
       COALESCE(rt.total_return_amount, 0) AS return_amount
FROM customer c
LEFT JOIN SalesAggregate s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN IncomeTrend it ON it.income_band = c.c_current_cdemo_sk
LEFT JOIN SalesReturn rt ON rt.web_web_page_id = (
    SELECT wp.wp_web_page_id 
    FROM web_page wp 
    WHERE wp.wp_customer_sk = c.c_customer_sk 
    ORDER BY wp.wp_creation_date_sk DESC LIMIT 1
)
WHERE (s.total_sales_value > 1000 OR s.total_quantity_sold > 100)
  AND (c.c_last_name IS NOT NULL AND c.c_last_name <> '')
  AND it.rank <= 10
ORDER BY s.total_sales_value DESC, it.total_sales DESC;
