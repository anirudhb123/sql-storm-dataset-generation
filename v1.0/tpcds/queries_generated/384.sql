
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 0
), buyer_info AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Female'
        END AS gender,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
), return_info AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), sales_summary AS (
    SELECT 
        item.i_item_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COALESCE(ri.total_returns, 0) AS total_returns,
        ri.total_return_amount,
        bi.gender,
        bi.hd_income_band_sk
    FROM 
        web_sales ws
    JOIN item ON ws.ws_item_sk = item.i_item_sk
    LEFT JOIN return_info ri ON ws.ws_item_sk = ri.sr_item_sk
    LEFT JOIN buyer_info bi ON ws.ws_bill_customer_sk = bi.c_customer_sk
    GROUP BY 
        item.i_item_id, bi.gender, bi.hd_income_band_sk
)
SELECT 
    ss.i_item_id,
    ss.total_sales_quantity,
    ss.total_sales_amount,
    ss.avg_sales_price,
    ss.total_returns,
    ss.total_return_amount,
    ba.total_buyers,
    ss.gender,
    ss.hd_income_band_sk
FROM 
    sales_summary ss
LEFT JOIN (
    SELECT 
        count(DISTINCT ws_bill_customer_sk) AS total_buyers
    FROM 
        web_sales
) ba ON true
WHERE 
    ss.total_sales_quantity > 1000
ORDER BY 
    ss.total_sales_amount DESC
LIMIT 100;
