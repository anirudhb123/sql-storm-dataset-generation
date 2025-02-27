
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_paid DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_country IS NULL OR c.c_country != '' 
    AND 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk)
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk IN (SELECT 
                                    d_date_sk 
                                  FROM 
                                    date_dim 
                                  WHERE 
                                    d_year = 2023 AND 
                                    d_dow = 6) 
    GROUP BY 
        sr_item_sk
),
PriceVariance AS (
    SELECT 
        i.i_item_sk,
        i.i_current_price,
        AVG(ws.ws_net_paid) AS avg_sales_price,
        (i.i_current_price - AVG(ws.ws_net_paid)) AS price_difference
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_current_price
    HAVING 
        ABS(i.i_current_price - AVG(ws.ws_net_paid)) > 50
)
SELECT 
    r.web_site_id,
    r.ws_order_number,
    r.ws_quantity,
    r.ws_net_paid,
    COALESCE(rr.total_returned, 0) AS total_returned,
    COALESCE(rr.total_return_amount, 0) AS total_return_amount,
    pv.price_difference
FROM 
    RankedSales r
LEFT JOIN 
    RecentReturns rr ON r.ws_order_number = rr.sr_item_sk
LEFT JOIN 
    PriceVariance pv ON r.ws_order_number = pv.i_item_sk
WHERE 
    r.rank_sales = 1 
AND 
    (pv.price_difference IS NOT NULL OR rr.total_returned > 0)
ORDER BY 
    r.web_site_id, r.ws_order_number;
