
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    LEFT JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        i.i_current_price > 0
        AND cd.cd_gender = 'F'
        AND (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
AggregateData AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (sd.total_sales - COALESCE(rd.total_returns, 0) * i.i_current_price) AS net_profit
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
)
SELECT 
    ad.ws_item_sk,
    ad.total_quantity,
    ad.total_sales,
    ad.total_returns,
    ad.net_profit,
    RANK() OVER (ORDER BY ad.net_profit DESC) AS profit_rank
FROM 
    AggregateData ad
WHERE 
    ad.net_profit > 0
ORDER BY 
    ad.net_profit DESC
LIMIT 10;
