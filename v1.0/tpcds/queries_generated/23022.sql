
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk <= 20250101
    GROUP BY ws_sold_date_sk, ws_item_sk
), 
customer_rank AS (
    SELECT 
        c_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY c_birth_year DESC) AS rank,
        MAX(cd_purchase_estimate) AS max_estimate
    FROM customer 
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_customer_sk
), 
item_stats AS (
    SELECT 
        i_item_sk,
        COUNT(CASE WHEN i_current_price < 50 THEN 1 END) AS low_price_count,
        COUNT(CASE WHEN i_current_price BETWEEN 50 AND 100 THEN 1 END) AS mid_price_count,
        COUNT(CASE WHEN i_current_price > 100 THEN 1 END) AS high_price_count,
        SUM(COALESCE(i_current_price, 0)) AS total_value
    FROM item 
    GROUP BY i_item_sk
), 
joined_sales AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        cs.total_quantity AS web_total_quantity,
        cs.total_sales AS web_total_sales,
        i.low_price_count,
        i.mid_price_count,
        i.high_price_count,
        i.total_value,
        CASE 
            WHEN cs.total_sales > 1000 THEN 'High'
            WHEN cs.total_sales IS NULL THEN 'Unknown'
            ELSE 'Low'
        END AS sales_classification
    FROM store_sales ss
    LEFT JOIN sales_summary cs ON ss.ss_item_sk = cs.ws_item_sk
    LEFT JOIN item_stats i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        ss.ss_sold_date_sk >= 20220101 
        AND ss.ss_quantity > (SELECT COALESCE(AVG(total_quantity), 10) FROM sales_summary) 
        AND ss.ss_sales_price BETWEEN 0 AND 200
)
SELECT 
    js.ss_sold_date_sk,
    js.ss_item_sk,
    js.ss_quantity,
    js.web_total_quantity,
    js.web_total_sales,
    js.low_price_count,
    js.mid_price_count,
    js.high_price_count,
    js.total_value,
    cr.c_customer_sk,
    cr.rank,
    cr.max_estimate,
    js.sales_classification
FROM joined_sales js
LEFT JOIN customer_rank cr ON cr.max_estimate = (
    SELECT MAX(cd_purchase_estimate)
    FROM customer_rank
    WHERE c_customer_sk = cr.c_customer_sk
)
WHERE 
    (js.web_total_sales IS NOT NULL OR js.web_total_quantity IS NULL) 
    OR (js.low_price_count > 10 AND js.mid_price_count < 5)
ORDER BY js.ss_sold_date_sk, js.ss_item_sk;
