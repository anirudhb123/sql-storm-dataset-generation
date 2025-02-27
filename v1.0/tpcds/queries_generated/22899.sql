
WITH RankedReturns AS (
    SELECT 
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        sr.return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr.item_sk ORDER BY sr.return_amt DESC) AS rnk
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(COALESCE(sr.return_amt, 0)) AS total_return_amt,
        AVG(COALESCE(sr.return_tax, 0)) AS avg_return_tax
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_returns,
        cs.total_return_amt,
        cs.avg_return_tax,
        DENSE_RANK() OVER (ORDER BY cs.total_return_amt DESC) AS customer_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_returns > 0
),
ItemSales AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
ReturnGain AS (
    SELECT 
        ir.item_sk,
        COALESCE(ss.total_net_profit, 0) - SUM(rr.return_amt) AS net_gain
    FROM 
        RankedReturns rr
    JOIN 
        item ir ON rr.item_sk = ir.i_item_sk
    LEFT JOIN 
        ItemSales ss ON ir.i_item_sk = ss.ws_item_sk
    GROUP BY 
        ir.item_sk, ss.total_net_profit
),
final_summary AS (
    SELECT 
        tc.c_customer_sk,
        tc.total_returns,
        tc.total_return_amt,
        tc.avg_return_tax,
        rg.net_gain,
        RANK() OVER (PARTITION BY tc.total_returns ORDER BY rg.net_gain DESC) AS gain_rank
    FROM 
        TopCustomers tc
    JOIN 
        ReturnGain rg ON tc.total_returns > 5
)
SELECT 
    fs.c_customer_sk,
    fs.total_returns,
    fs.total_return_amt,
    fs.avg_return_tax,
    fs.net_gain,
    CASE 
        WHEN fs.gain_rank IS NULL THEN 'Not Ranked'
        WHEN fs.gain_rank <= 3 THEN 'Top Gainer'
        ELSE 'Regular Gainer'
    END AS gain_status
FROM 
    final_summary fs
WHERE 
    fs.net_gain > 0
ORDER BY 
    fs.total_return_amt DESC, fs.net_gain DESC;
