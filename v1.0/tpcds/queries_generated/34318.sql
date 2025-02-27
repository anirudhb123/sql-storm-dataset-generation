
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_day_name
    FROM date_dim
    WHERE d_year = 2023
    UNION ALL
    SELECT dd.d_date_sk, dd.d_date, dd.d_year, dd.d_month_seq, dd.d_week_seq, dd.d_day_name
    FROM date_dim dd
    JOIN DateHierarchy dh ON dd.d_date_sk = dh.d_date_sk + 1
    WHERE dd.d_year = 2023
),
CustomerStats AS (
    SELECT c.c_customer_id, 
           cd.cd_gender, 
           COUNT(DISTINCT ss_ticket_number) AS total_sales,
           SUM(ss_sales_price) AS total_spent,
           DENSE_RANK() OVER(PARTITION BY cd.cd_gender ORDER BY SUM(ss_sales_price) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
),
ReturnsCTE AS (
    SELECT sr_item_sk, 
           SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesSummary AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_sold,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COALESCE(ret.total_returns, 0) AS total_returns
    FROM web_sales ws
    LEFT JOIN ReturnsCTE ret ON ws.ws_item_sk = ret.sr_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT d.d_year,
       COUNT(DISTINCT cs.c_customer_id) AS unique_customers,
       SUM(ss.total_sold) AS total_items_sold,
       SUM(ss.total_net_profit) AS total_net_profit,
       MAX(cs.gender_rank) AS highest_gender_rank
FROM DateHierarchy d
JOIN CustomerStats cs ON cs.total_sales > 0
JOIN SalesSummary ss ON ss.total_sold > 0
WHERE d.d_date_sk BETWEEN 1 AND 365
GROUP BY d.d_year;
