
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_profit
    FROM 
        SalesSummary ss
    WHERE 
        ss.profit_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
IncomeProfile AS (
    SELECT 
        hd.hd_income_band_sk,
        AVG(hd.hd_dep_count) AS avg_dep_count
    FROM 
        household_demographics hd
    GROUP BY 
        hd.hd_income_band_sk
    HAVING 
        AVG(hd.hd_dep_count) > 2
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    ip.hd_income_band_sk,
    ip.avg_dep_count,
    CASE 
        WHEN cd.customer_count IS NULL THEN 'No Customers'
        ELSE cd.customer_count::TEXT
    END AS customer_count
FROM 
    TopItems ti
LEFT JOIN 
    CustomerDemographics cd ON ti.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c))
LEFT JOIN 
    IncomeProfile ip ON ip.hd_income_band_sk IN (SELECT hd.hd_income_band_sk FROM household_demographics hd)
ORDER BY 
    ti.total_net_profit DESC
LIMIT 50;
