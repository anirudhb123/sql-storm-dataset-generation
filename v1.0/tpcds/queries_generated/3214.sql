
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
MaxReturns AS (
    SELECT 
        sr_item_sk, 
        return_count,
        total_return_amount
    FROM 
        CustomerReturns
    WHERE 
        return_count = (SELECT MAX(return_count) FROM CustomerReturns)
),
DateDetails AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        COUNT(*) AS total_sales
    FROM 
        date_dim AS d
    JOIN 
        web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_quarter_seq
)
SELECT 
    i.i_item_id,
    SUM(sd.total_quantity) AS total_sold,
    COALESCE(mr.return_count, 0) AS total_returns,
    COALESCE(mr.total_return_amount, 0) AS total_return_value,
    dd.total_sales,
    i.i_current_price,
    dd.d_year,
    dd.d_month_seq,
    dd.d_quarter_seq
FROM 
    SalesData AS sd
JOIN 
    item AS i ON sd.ws_item_sk = i.i_item_sk
LEFT JOIN 
    MaxReturns AS mr ON i.i_item_sk = mr.sr_item_sk
JOIN 
    DateDetails AS dd ON dd.total_sales > 0
WHERE 
    sd.rn = 1
GROUP BY 
    i.i_item_id, i.i_current_price, dd.d_year, dd.d_month_seq, dd.d_quarter_seq
ORDER BY 
    total_sold DESC, total_return_value DESC;
