
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        d.d_date,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS YearRank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, ws.ws_sales_price, ws.ws_net_profit, d.d_date, d.d_year
),
ReturnData AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_net_profit,
        COALESCE(rd.total_returned, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        COUNT(sd.ws_order_number) AS order_count
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.cr_item_sk
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cd.total_net_profit,
    cd.total_returns,
    cd.total_return_amount,
    cd.order_count
FROM 
    CombinedData cd
JOIN 
    item i ON cd.ws_item_sk = i.i_item_sk
WHERE 
    cd.total_net_profit > (SELECT AVG(total_net_profit) FROM CombinedData)
    AND cd.total_returns < cd.order_count
ORDER BY 
    cd.total_net_profit DESC
LIMIT 10;
