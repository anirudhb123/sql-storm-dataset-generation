
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank_by_date
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
    GROUP BY ws.web_site_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        sd.web_site_sk,
        sd.total_quantity,
        sd.total_sales
    FROM SalesData sd
    WHERE sd.rank_by_date <= 5
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        SUM(ts.total_sales) AS total_purchases,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN TopSales ts ON c.c_customer_sk = ts.web_site_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_buy_potential
),
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.buy_potential,
        cd.total_purchases,
        cd.total_return_qty,
        cd.total_return_amt,
        CASE 
            WHEN cd.total_purchases IS NULL THEN 'NO PURCHASES'
            WHEN cd.total_return_amt > 0 THEN 'MORE RETURNS THAN SALES'
            ELSE 'PROFITABLE CUSTOMER'
        END AS customer_status
    FROM CustomerData cd
)
SELECT 
    fr.c_customer_id,
    fr.cd_gender,
    fr.buy_potential,
    fr.total_purchases,
    fr.total_return_qty,
    fr.total_return_amt,
    fr.customer_status
FROM FinalReport fr
ORDER BY fr.total_purchases DESC NULLS LAST
LIMIT 100;
