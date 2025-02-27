
WITH RECURSIVE sales_trends AS (
    SELECT
        ss.sold_date_sk,
        SUM(ss.net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.sold_date_sk ORDER BY SUM(ss.net_profit) DESC) AS rank
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
    GROUP BY
        ss.sold_date_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY c.c_customer_sk) AS income_rank
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
return_stats AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_net_loss) AS total_loss
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
promotional_performance AS (
    SELECT
        p.p_promo_id,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY
        p.p_promo_id
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(rt.total_returns, 0) AS total_returns,
    COALESCE(rt.total_loss, 0) AS total_loss,
    sp.total_profit,
    pp.total_sales,
    pp.total_discounts,
    pp.total_net_profit
FROM
    customer_details cd
LEFT JOIN return_stats rt ON cd.c_customer_sk = rt.sr_item_sk
LEFT JOIN sales_trends sp ON cd.c_customer_sk = sp.sold_date_sk
LEFT JOIN income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotional_performance pp ON pp.total_sales > 1000  -- only include successful promotions
WHERE
    cd.income_rank <= 5
ORDER BY
    cd.c_first_name, cd.c_last_name;
