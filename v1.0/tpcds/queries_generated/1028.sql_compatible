
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_item_sk
),
top_sales AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM
        sales_summary ss
    JOIN item i ON ss.ws_item_sk = i.i_item_sk
    WHERE
        ss.sales_rank <= 10
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_details AS (
    SELECT
        tt.ws_item_sk,
        SUM(tt.ws_quantity) AS quantity_sold,
        SUM(tt.ws_net_profit) AS total_profit
    FROM
        web_sales tt
    GROUP BY
        tt.ws_item_sk
),
sales_ranks AS (
    SELECT
        sd.ws_item_sk,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM
        sales_details sd
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.i_current_price,
    ts.i_brand,
    ts.i_category,
    COALESCE(ib.ib_lower_bound, 0) AS income_lower,
    COALESCE(ib.ib_upper_bound, 0) AS income_upper
FROM
    top_sales ts
JOIN customer_info ci ON ci.c_customer_sk IN (
    SELECT 
        DISTINCT ws_bill_customer_sk 
    FROM 
        web_sales 
    WHERE 
        ws_item_sk = ts.ws_item_sk
)
LEFT JOIN income_band ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
WHERE
    (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
ORDER BY
    ts.total_sales DESC, 
    ci.c_last_name;
