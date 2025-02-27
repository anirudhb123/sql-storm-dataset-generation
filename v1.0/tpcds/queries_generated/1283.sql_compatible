
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
PromotionsUsed AS (
    SELECT 
        p_promo_sk,
        COUNT(DISTINCT ws_order_number) AS promo_orders
    FROM 
        web_sales
    JOIN 
        promotion ON ws_promo_sk = p_promo_sk
    GROUP BY 
        p_promo_sk
),
CustomerReturns AS (
    SELECT 
        ws_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SD.total_quantity, 0) AS total_quantity,
    COALESCE(SD.total_sales, 0) AS total_sales,
    COALESCE(PR.promo_orders, 0) AS total_promotions,
    COALESCE(CR.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(SD.total_quantity, 0) = 0 THEN NULL
        ELSE ROUND(COALESCE((COALESCE(SD.total_sales, 0) - COALESCE(CR.total_returns, 0)) / NULLIF(SD.total_quantity, 0), 0), 2)
    END AS sales_per_unit
FROM 
    item i
LEFT JOIN 
    SalesData SD ON i.i_item_sk = SD.ws_item_sk
LEFT JOIN 
    PromotionsUsed PR ON PR.p_promo_sk = (SELECT p_promo_sk FROM promotion WHERE p_item_sk = i.i_item_sk)
LEFT JOIN 
    CustomerReturns CR ON CR.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
