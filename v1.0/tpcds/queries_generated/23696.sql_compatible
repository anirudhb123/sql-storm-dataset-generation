
WITH RankedSales AS (
    SELECT 
        ws.item_sk,
        ws.order_number,
        ws_ext_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank,
        COALESCE(ws_ext_discount_amt, 0) AS discount_amount
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        (hd.hd_income_band_sk IS NULL OR hd.hd_income_band_sk IN 
            (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000)
        )
        AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
), ReturnInfo AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 10
)

SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    s.ss_sales_price, 
    rs.discount_amount,
    s.ss_net_profit,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller'
        WHEN rs.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Regular Seller'
    END AS seller_category
FROM 
    RankedSales rs
JOIN 
    store_sales s ON rs.item_sk = s.ss_item_sk AND rs.order_number = s.ss_ticket_number
JOIN 
    CustomerInfo ci ON s.ss_customer_sk = ci.c_customer_sk
LEFT JOIN 
    ReturnInfo rinfo ON rinfo.sr_item_sk = rs.item_sk
WHERE 
    s.ss_net_profit > 0
    AND (rinfo.total_returns IS NULL OR rinfo.total_returns < 5)
ORDER BY 
    s.ss_net_profit DESC, 
    ci.c_last_name ASC
LIMIT 100;
