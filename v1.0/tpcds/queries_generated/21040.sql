
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
), 
TopItems AS (
    SELECT 
        R.ws_item_sk,
        R.total_sales,
        I.i_item_desc,
        I.i_brand,
        I.i_size,
        D.d_year,
        COALESCE(SR.reason_desc, 'No Reason') AS return_reason
    FROM 
        RankedSales R
    JOIN 
        item I ON R.ws_item_sk = I.i_item_sk
    LEFT JOIN 
        (SELECT 
            sr_item_sk, 
            sr_return_reason_sk,
            RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS return_rank
         FROM 
            store_returns
         GROUP BY 
            sr_item_sk, sr_return_reason_sk
         HAVING 
            return_rank <= 3) SR ON I.i_item_sk = SR.sr_item_sk
    JOIN 
        date_dim D ON D.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = D.d_year)
    WHERE 
        R.sales_rank = 1
)
SELECT 
    T.i_item_desc,
    T.i_brand,
    T.i_size,
    T.total_sales,
    T.return_reason,
    (SELECT COUNT(*) FROM store_sales S WHERE S.ss_item_sk = T.ws_item_sk AND S.ss_sold_date_sk BETWEEN 1 AND 30) AS last_month_sales,
    (SELECT AVG(ws_net_profit) FROM web_sales W WHERE W.ws_item_sk = T.ws_item_sk) AS avg_profit,
    (SELECT SUM(CASE WHEN ws_quantity = 0 THEN 1 ELSE 0 END) FROM web_sales WHERE ws_item_sk = T.ws_item_sk) AS out_of_stock_count
FROM 
    TopItems T
WHERE 
    (T.total_sales IS NOT NULL OR T.return_reason IS NOT NULL) AND 
    (T.i_size = 'L' OR T.i_size IS NULL)
ORDER BY 
    T.total_sales DESC, 
    T.i_size NULLS LAST;
