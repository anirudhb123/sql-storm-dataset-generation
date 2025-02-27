
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss.sold_date_sk,
        ss.store_sk,
        ss.item_sk,
        SUM(ss.quantity) AS total_quantity,
        SUM(ss.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.net_profit) DESC) AS rank
    FROM 
        store_sales ss 
    GROUP BY 
        ss.sold_date_sk, ss.store_sk, ss.item_sk
),
top_sales AS (
    SELECT 
        s.store_id,
        s.store_name,
        ss.item_sk,
        ss.total_quantity,
        ss.total_net_profit
    FROM 
        store s
    JOIN sales_summary ss ON s.s_store_sk = ss.store_sk
    WHERE 
        ss.rank <= 5
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
date_series AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS seq
    FROM 
        date_dim d
    WHERE
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ds.d_date,
    ds.d_year,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    ts.store_id,
    ts.store_name,
    ts.item_sk,
    ts.total_quantity,
    ts.total_net_profit
FROM 
    date_series ds
JOIN 
    web_sales ws ON ws.ws_sold_date_sk = ds.d_date_sk
JOIN 
    customer_info c ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    top_sales ts ON ts.item_sk = ws.ws_item_sk
WHERE 
    (ts.total_net_profit > 1000 AND c.cd_purchase_estimate > 5000)
    OR (ts.total_quantity < 10 AND c.cd_marital_status = 'M')
ORDER BY 
    ds.d_date, ts.total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
