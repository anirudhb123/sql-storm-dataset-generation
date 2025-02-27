
WITH CustomerPurchases AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_quantity) AS total_quantity, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cp.total_quantity, cp.total_sales
    FROM CustomerPurchases cp
    JOIN customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    ORDER BY cp.total_sales DESC
    LIMIT 5
),
StoreDetails AS (
    SELECT s.s_store_sk, s.s_store_name, SUM(ss.ss_quantity) AS total_sold_items
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
PromotionSummary AS (
    SELECT p.p_promo_name, COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count, SUM(ws.ws_net_profit) AS total_profit
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.promo_name
),
FinalMetrics AS (
    SELECT tc.c_first_name, tc.c_last_name, sd.s_store_name, ps.promo_name, ps.promo_sales_count, ps.total_profit
    FROM TopCustomers tc
    CROSS JOIN StoreDetails sd
    CROSS JOIN PromotionSummary ps
)
SELECT * 
FROM FinalMetrics
ORDER BY total_profit DESC, promo_sales_count DESC;
