
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        ws.ws_ship_date_sk,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ship_date_sk DESC) AS recent_sales,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE d.d_year >= 2022
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_order_number,
        sd.ws_sales_price,
        sd.ws_ext_discount_amt,
        sd.ws_ext_sales_price,
        sd.total_quantity,
        RANK() OVER (ORDER BY sd.total_quantity DESC) AS sales_rank
    FROM SalesData sd
    WHERE sd.recent_sales = 1
),
PromotionData AS (
    SELECT 
        p.p_promo_id,
        p.p_cost,
        p.p_response_target
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    UNION ALL
    SELECT
        p.p_promo_id,
        p.p_cost,
        p.p_response_target
    FROM promotion p
    WHERE p.p_response_target IS NULL
),
FinalResult AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_order_number,
        ts.ws_sales_price,
        ts.ws_ext_sales_price,
        COALESCE(pd.p_promo_id, 'No Promo') AS promo_id,
        CASE 
            WHEN ts.total_quantity > 10 THEN 'High Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM TopSales ts
    LEFT JOIN PromotionData pd ON ts.ws_order_number % 5 = pd.p_response_target
)
SELECT 
    f.ws_item_sk,
    f.ws_order_number,
    f.ws_sales_price,
    f.ws_ext_sales_price,
    f.promo_id,
    f.volume_category,
    CASE 
        WHEN f.ws_ext_sales_price IS NULL THEN 'Price Not Available'
        ELSE CONCAT('Final Price after Discount: ', f.ws_ext_sales_price - (f.ws_ext_sales_price * 0.10))
    END AS final_price,
    JSON_AGG(DISTINCT CONCAT('Item:', f.ws_item_sk, ', Order:', f.ws_order_number)) FILTER (WHERE f.ws_sales_price > 0) AS sales_summary
FROM FinalResult f
GROUP BY f.ws_item_sk, f.ws_order_number, f.ws_sales_price, f.ws_ext_sales_price, f.promo_id, f.volume_category
ORDER BY f.volume_category DESC, f.ws_ext_sales_price DESC
LIMIT 100;
