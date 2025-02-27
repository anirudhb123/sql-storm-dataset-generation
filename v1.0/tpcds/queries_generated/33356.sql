
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerCTE AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_income_band_sk
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_purchase_estimate > 5000
),
StoreSalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 1 AND 365
    GROUP BY ss_store_sk
),
ItemSales AS (
    SELECT 
        i_item_sk,
        i_product_name,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_sales_price) AS avg_sales_price
    FROM web_sales
    JOIN item ON ws_item_sk = i_item_sk
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY i_item_sk, i_product_name
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_store_sales,
    COALESCE(cs.total_quantity_sold, 0) AS total_web_sales,
    cs.total_profit,
    cs.avg_sales_price,
    r.r_reason_desc,
    s.s_store_name,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS store_ranking
FROM CustomerCTE c
LEFT JOIN StoreSalesCTE ss ON c.c_customer_sk = ss.ss_store_sk
LEFT JOIN ItemSales cs ON c.c_customer_sk = cs.i_item_sk
LEFT JOIN reason r ON r.r_reason_sk = (SELECT sr_reason_sk FROM store_returns WHERE sr_return_quantity > 0 AND sr_customer_sk = c.c_customer_sk)
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE (c.cd_gender = 'F' OR c.cd_marital_status = 'M') AND cs.total_quantity_sold > 10
ORDER BY total_store_sales DESC, total_profit DESC
LIMIT 100;
