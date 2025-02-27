
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        i.i_item_desc,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk >= 2451545 -- Example date filter
),
CalculatedReturns AS (
    SELECT 
        CASE 
            WHEN sr.returned_date IS NOT NULL THEN 'Store Return'
            WHEN wr.returned_date IS NOT NULL THEN 'Web Return'
            ELSE 'No Return'
        END AS return_type,
        sd.*
    FROM 
        SalesData sd
    LEFT JOIN 
        store_returns sr ON sr.sr_item_sk = sd.ws_item_sk AND sr.sr_returned_date_sk = sd.ws_sold_date_sk
    LEFT JOIN 
        web_returns wr ON wr.wr_item_sk = sd.ws_item_sk AND wr.wr_returned_date_sk = sd.ws_sold_date_sk
),
AggSales AS (
    SELECT 
        return_type,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(i_current_price) AS avg_price
    FROM 
        CalculatedReturns
    WHERE 
        rn = 1
    GROUP BY 
        return_type
),
IncomeBandCounts AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS count_per_band
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    a.return_type,
    a.total_quantity,
    a.total_net_profit,
    a.avg_price,
    COALESCE(ibc.count_per_band, 0) AS customer_count_per_income_band
FROM 
    AggSales a
LEFT JOIN 
    IncomeBandCounts ibc ON a.return_type = CASE 
        WHEN a.return_type = 'No Return' THEN 'N/A' 
        ELSE 'Has Return' 
    END
ORDER BY 
    a.total_net_profit DESC;
