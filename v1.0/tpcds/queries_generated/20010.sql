
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451537 AND 2451604
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_credit_rating, 'UNKNOWN') AS credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'NO DEPENDENTS'
            ELSE CONCAT('DEPENDENTS: ', cd.cd_dep_count) 
        END AS dependents_info
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_stock AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    INNER JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
sales_analysis AS (
    SELECT 
        ri.ws_bill_customer_sk AS customer_sk,
        ri.ws_item_sk AS item_sk,
        SUM(ri.ws_quantity) AS total_quantity,
        SUM(ri.ws_sales_price * ri.ws_quantity) AS total_sales_value,
        COALESCE(is.total_stock, 0) AS stock_level
    FROM ranked_sales ri
    LEFT JOIN item_stock is ON ri.ws_item_sk = is.i_item_sk
    GROUP BY ri.ws_bill_customer_sk, ri.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    sa.item_sk,
    sa.total_quantity,
    sa.total_sales_value,
    sa.stock_level,
    CASE 
        WHEN sa.stock_level = 0 THEN 'OUT OF STOCK' 
        ELSE 'IN STOCK' 
    END AS stock_status,
    (SELECT COUNT(DISTINCT sr_ticket_number) 
     FROM store_returns sr 
     WHERE sr.sr_customer_sk = sa.customer_sk) AS total_returns,
    (SELECT COUNT(DISTINCT cr_order_number) 
     FROM catalog_returns cr 
     WHERE cr.cr_returning_customer_sk = sa.customer_sk) AS catalog_returns
FROM sales_analysis sa
JOIN customer_info ci ON sa.customer_sk = ci.c_customer_sk
WHERE sa.total_sales_value > (
    SELECT AVG(total_sales_value) 
    FROM sales_analysis 
    WHERE customer_sk = sa.customer_sk
)
ORDER BY ci.c_last_name, ci.c_first_name, sa.total_sales_value DESC;

