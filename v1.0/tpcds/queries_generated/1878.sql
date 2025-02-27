
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        RS.total_quantity,
        RS.total_net_paid
    FROM 
        item
    JOIN 
        RankedSales RS ON item.i_item_sk = RS.ws_item_sk
    WHERE 
        RS.rank_sales <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalReport AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ti.i_item_desc,
        ti.total_quantity,
        ti.total_net_paid,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM 
        customer ci
    LEFT JOIN 
        TopItems ti ON ti.total_net_paid > 100 AND ci.c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns)
    LEFT JOIN 
        CustomerReturns cr ON ci.c_customer_sk = cr.sr_customer_sk
    WHERE 
        ci.c_current_cdemo_sk IS NOT NULL
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.i_item_desc,
    fr.total_quantity,
    fr.total_net_paid,
    fr.total_returns,
    fr.total_return_amt
FROM 
    FinalReport fr
ORDER BY 
    fr.total_net_paid DESC, fr.c_last_name ASC
LIMIT 50;
