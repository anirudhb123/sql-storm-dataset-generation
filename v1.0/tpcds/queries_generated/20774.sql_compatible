
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_value,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerIncome AS (
    SELECT 
        c.c_customer_sk, 
        h.hd_income_band_sk,
        CASE 
            WHEN h.hd_income_band_sk IS NULL THEN 'Unknown' 
            ELSE CONCAT('Income Band: ', h.hd_income_band_sk)
        END AS income_band_description
    FROM customer c
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_discount
    FROM promotion p
    GROUP BY p.p_promo_id, p.p_promo_name
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
TopReturns AS (
    SELECT 
        rr.*, 
        ci.income_band_description,
        p.total_discount,
        sd.total_sales_quantity,
        sd.total_sales_amount
    FROM RankedReturns rr
    LEFT JOIN CustomerIncome ci ON rr.sr_item_sk = ci.c_customer_sk
    LEFT JOIN Promotions p ON rr.sr_item_sk = p.p_promo_id
    LEFT JOIN SalesData sd ON rr.sr_item_sk = sd.ws_item_sk
)
SELECT 
    tr.sr_item_sk,
    tr.total_returned,
    tr.total_return_value,
    tr.income_band_description,
    COALESCE(tr.total_discount, 0) AS total_discount_received,
    COALESCE(tr.total_sales_quantity, 0) AS total_sales_made,
    COALESCE(tr.total_sales_amount, 0) AS total_sales_value,
    CASE 
        WHEN tr.total_returned > 0 THEN 'Return High'
        WHEN tr.total_sales_quantity > 100 THEN 'High Sales'
        ELSE 'Regular'
    END AS return_sales_category
FROM TopReturns tr
WHERE tr.rank = 1
ORDER BY tr.total_return_value DESC, tr.sr_item_sk;
