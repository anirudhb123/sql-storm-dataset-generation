
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
HighProfitItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.profit_rank <= 10
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(i.i_brand, 'Unknown') AS item_brand,
        COALESCE(i.i_category, 'Unknown') AS item_category
    FROM 
        item i
)
SELECT 
    id.item_brand,
    id.item_category,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
    SUM(hpi.total_quantity) AS total_sales_quantity,
    SUM(hpi.total_net_profit) AS total_sales_profit,
    COUNT(DISTINCT cd.cd_demo_sk) AS distinct_customers
FROM 
    HighProfitItems hpi
JOIN 
    ItemDetails id ON hpi.ws_item_sk = id.i_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= 50000 AND ib_upper_bound >= 100000)
GROUP BY 
    id.item_brand, id.item_category, cd.cd_gender, cd.cd_marital_status
HAVING 
    total_sales_profit > 10000
ORDER BY 
    total_sales_profit DESC;
