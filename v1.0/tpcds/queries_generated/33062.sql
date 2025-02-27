
WITH RECURSIVE sales_cte AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM store_sales
    WHERE ss_sold_date_sk > (
        SELECT MAX(ss_sold_date_sk) - 365 
        FROM store_sales
    )
    GROUP BY ss_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd_cd_gender,
        hd_income_band_sk,
        COALESCE(cd_dep_count, 0) AS dependent_count,
        COALESCE(cd_credit_rating, 'Unknown') AS credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
best_selling_items AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank,
        s.item,
        inv.inv_quantity_on_hand,
        ci.c_customer_id,
        ci.credit_rating
    FROM sales_cte s
    JOIN inventory inv ON s.ss_item_sk = inv.inv_item_sk
    JOIN customer_info ci ON ci.hd_income_band_sk = 
        (SELECT ib_income_band_sk 
         FROM income_band 
         WHERE (ib_lower_bound <= 50000 AND ib_upper_bound >= 0) 
         LIMIT 1)
    WHERE s.profit_rank <= 10
)
SELECT 
    b.rank,
    b.item,
    b.inv_quantity_on_hand,
    ci.c_customer_id,
    ci.credit_rating,
    CASE 
        WHEN b.inv_quantity_on_hand IS NULL THEN 'Out of stock'
        ELSE 'In stock'
    END AS stock_status
FROM best_selling_items b
FULL OUTER JOIN customer_info ci ON ci.c_customer_id IS NOT NULL
ORDER BY b.rank;
