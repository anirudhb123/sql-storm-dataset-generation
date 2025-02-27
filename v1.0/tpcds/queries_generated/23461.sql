
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2022, 2023)
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        sd.ws_net_profit,
        rd.total_returns,
        rd.total_return_amt
    FROM SalesData sd
    LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE sd.rn <= 10
),
FinalData AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_sales_price,
        ts.ws_quantity,
        ts.ws_net_profit,
        COALESCE(ts.total_returns, 0) AS total_returns,
        COALESCE(ts.total_return_amt, 0.00) AS total_return_amt,
        CASE 
            WHEN COALESCE(ts.total_returns, 0) = 0 THEN 'No returns'
            ELSE 'Returned'
        END AS return_status
    FROM TopSales ts
)
SELECT 
    fd.ws_item_sk,
    fd.ws_sales_price,
    fd.ws_quantity,
    fd.ws_net_profit,
    fd.total_returns,
    fd.total_return_amt,
    fd.return_status,
    (
        SELECT 
            SUM(cd_purchase_estimate) 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk IN (
            SELECT c.c_current_cdemo_sk 
            FROM customer c 
            WHERE c.c_customer_sk IN (
                SELECT ss.ss_customer_sk 
                FROM store_sales ss 
                WHERE ss.ss_item_sk = fd.ws_item_sk
            )
        )
    ) AS total_estimated_purchases
FROM FinalData fd
WHERE fd.ws_net_profit > (
    SELECT AVG(ws_net_profit) 
    FROM SalesData 
)
ORDER BY fd.ws_net_profit DESC
LIMIT 100;
