
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM 
        store_returns
    WHERE
        sr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
    GROUP BY 
        sr_item_sk
),
TopReturns AS (
    SELECT 
        r.sr_item_sk,
        r.return_count,
        r.total_return_amt,
        i.i_item_desc, 
        i.i_current_price,
        i.i_brand,
        i.category,
        i.i_class,
        i.i_size
    FROM 
        RankedReturns r
    JOIN 
        item i ON r.sr_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
),
SalesSummary AS (
    SELECT 
        w.ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions
    FROM 
        web_sales w
    WHERE 
        w.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
    GROUP BY 
        w.ws_item_sk
)
SELECT 
    t.sr_item_sk,
    t.return_count,
    t.total_return_amt,
    s.total_sales,
    s.total_transactions,
    (t.total_return_amt / NULLIF(s.total_sales, 0)) AS return_rate,
    t.i_item_desc,
    t.i_current_price,
    t.i_brand,
    t.i_class,
    t.i_size
FROM 
    TopReturns t
LEFT JOIN 
    SalesSummary s ON t.sr_item_sk = s.ws_item_sk
ORDER BY 
    return_rate DESC;
