
WITH sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ss.total_quantity,
        ss.total_net_paid
    FROM sales_summary ss
    JOIN item ON ss.ws_item_sk = item.i_item_sk
    WHERE ss.rank_sales <= 10
),
customers AS (
    SELECT 
        c.c_customer_id,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
returns_summary AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt) AS total_return_amt
    FROM catalog_returns 
    GROUP BY cr_item_sk
)

SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_net_paid,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM top_items ti
LEFT JOIN returns_summary rs ON ti.ws_item_sk = rs.cr_item_sk
CROSS JOIN customers c
WHERE ti.total_net_paid > 100
GROUP BY ti.i_item_id, ti.i_item_desc, ti.total_quantity, ti.total_net_paid, rs.total_returns, rs.total_return_amt
HAVING COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY ti.total_net_paid DESC;
