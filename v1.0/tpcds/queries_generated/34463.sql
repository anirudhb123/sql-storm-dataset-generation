
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
RecentTopSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        COALESCE(NULLIF(SUM(sr_return_quantity), 0), 1) AS returns,
        SUM(ws_quantity) OVER (PARTITION BY s.ws_item_sk) AS total_quantity_sold,
        (SUM(ws_net_profit) / NULLIF(NULLIF(SUM(ws_net_paid), 0), SUM(ws_coupon_amt))) AS profit_margin
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        store_returns sr ON sr.sr_item_sk = s.ws_item_sk
    WHERE 
        s.rank = 1
    GROUP BY 
        s.ws_item_sk, i.i_item_desc, i.i_brand, i.i_category, i.i_current_price
)
SELECT 
    r.ws_item_sk,
    r.total_sales,
    r.i_item_desc,
    r.i_brand,
    r.i_category,
    r.i_current_price,
    r.returns,
    r.total_quantity_sold,
    r.profit_margin
FROM 
    RecentTopSales r
WHERE 
    r.total_sales > 10000
    AND r.profit_margin IS NOT NULL
ORDER BY 
    r.total_sales DESC
LIMIT 10;

