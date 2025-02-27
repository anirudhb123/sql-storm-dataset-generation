
WITH RECURSIVE return_details AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity > 0
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
promotional_analysis AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discounts
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_start_date_sk IS NOT NULL AND p.p_end_date_sk IS NOT NULL
    GROUP BY p.p_promo_id
),
active_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        COALESCE(SUM(sd.ss_ext_sales_price), 0) AS total_sales_amount
    FROM customer_info ci
    LEFT JOIN store_sales sd ON ci.c_customer_sk = sd.ss_customer_sk
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    HAVING total_sales_amount >= 500
),
order_summary AS (
    SELECT 
        a.c_customer_sk,
        COUNT(DISTINCT sr.return_rank IS NULL) AS return_count,
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(CASE WHEN sr.sr_return_quantity IS NULL THEN 0 ELSE 1 END) AS count_of_returns
    FROM active_customers a
    JOIN return_details sr ON a.c_customer_sk = sr.sr_item_sk
    GROUP BY a.c_customer_sk
)
SELECT 
    ac.c_customer_sk,
    ac.c_first_name,
    ac.c_last_name,
    coalesce(p.total_sales, 0) AS promotional_sales,
    o.return_count,
    o.total_returned_quantity,
    o.total_returned_amount
FROM active_customers ac
FULL OUTER JOIN promotional_analysis p ON ac.c_customer_sk = p.total_sales
FULL OUTER JOIN order_summary o ON ac.c_customer_sk = o.c_customer_sk
WHERE coalesce(p.total_sales, 0) > 0 OR o.total_returned_quantity > 0
ORDER BY ac.c_first_name ASC, ac.c_last_name DESC;
