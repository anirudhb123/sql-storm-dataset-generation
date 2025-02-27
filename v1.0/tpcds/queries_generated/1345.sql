
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
HighProfitSales AS (
    SELECT 
        rs.ws_order_number, 
        rs.ws_item_sk, 
        rs.ws_quantity, 
        rs.ws_sales_price, 
        rs.ws_net_profit, 
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ib.ib_income_band_sk
    FROM 
        RankedSales rs
    JOIN 
        CustomerDetails cd ON cd.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = rs.ws_order_number LIMIT 1)
    JOIN 
        income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        rs.profit_rank <= 5
)
SELECT 
    hps.ws_order_number,
    hps.ws_item_sk,
    hps.ws_quantity,
    hps.ws_sales_price,
    hps.ws_net_profit,
    COUNT(ts.total_returns) AS return_count,
    SUM(ts.total_return_amount) AS return_sum,
    COUNT(DISTINCT hd.hd_income_band_sk) AS unique_income_bands
FROM 
    HighProfitSales hps
LEFT JOIN 
    TotalSales ts ON hps.ws_item_sk = ts.sr_store_sk
FULL OUTER JOIN 
    household_demographics hd ON hps.hd_income_band_sk = hd.hd_income_band_sk
WHERE 
    hps.ws_net_profit > 0 AND (hd.hd_vehicle_count IS NULL OR hd.hd_vehicle_count > 0)
GROUP BY 
    hps.ws_order_number, hps.ws_item_sk, hps.ws_quantity, hps.ws_sales_price, hps.ws_net_profit
ORDER BY 
    hps.ws_net_profit DESC;
