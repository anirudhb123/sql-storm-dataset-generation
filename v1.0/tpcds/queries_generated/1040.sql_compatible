
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ship_mode_sk,
        ws.ws_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_sales
    FROM
        web_sales ws
    INNER JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND ws.ws_quantity > 0
),
TopSales AS (
    SELECT *
    FROM SalesData
    WHERE rank_sales <= 10
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr 
    GROUP BY 
        wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(ts.total_returned, 0) AS total_returned,
        COALESCE(ts.total_return_amount, 0) AS total_return_amount,
        ts.ws_quantity,
        ts.ws_sales_price,
        ts.ws_ext_sales_price
    FROM 
        item i
    LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN ReturnData rd ON i.i_item_sk = rd.wr_item_sk
)
SELECT 
    fr.i_item_id,
    fr.i_item_desc,
    fr.total_returned,
    fr.total_return_amount,
    fr.ws_quantity,
    fr.ws_sales_price,
    fr.ws_ext_sales_price,
    CASE
        WHEN fr.total_returned > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN fr.ws_sales_price IS NULL THEN 'Price Not Available'
        ELSE FORMAT(fr.ws_sales_price, 'C')
    END AS formatted_price,
    CASE 
        WHEN fr.total_return_amount IS NULL THEN 'No Returns'
        ELSE FORMAT(fr.total_return_amount, 'C')
    END AS formatted_return_amount
FROM 
    FinalReport fr
ORDER BY 
    fr.ws_ext_sales_price DESC;
