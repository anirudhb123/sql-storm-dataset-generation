
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450450
),
TopProfitableSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rn <= 10
    GROUP BY 
        sd.ws_item_sk
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    tp.ws_item_sk,
    tp.total_profit,
    ib.ib_income_band_sk,
    ib.customer_count,
    COALESCE((SELECT AVG(ws.ws_net_profit) 
              FROM web_sales ws 
              WHERE ws.ws_item_sk = tp.ws_item_sk), 0) AS avg_net_profit
FROM 
    TopProfitableSales tp
LEFT JOIN 
    IncomeBands ib ON tp.total_profit < (SELECT AVG(total_profit) FROM TopProfitableSales)
ORDER BY 
    tp.total_profit DESC, 
    ib.customer_count ASC;
