
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450038 AND 2450070
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        ib.ib_income_band_sk,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_dep_count AS VARCHAR)
        END AS dep_count_label
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
AggregateSales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_net_profit) AS total_net_profit,
        SUM(s.ws_quantity) AS total_quantity_sold
    FROM 
        SalesData s
    WHERE 
        s.rnk = 1
    GROUP BY 
        s.ws_item_sk
)
SELECT 
    it.i_item_id, 
    it.i_item_desc,
    COALESCE(cd.cd_gender, 'Not Specified') AS gender,
    SUM(asales.total_net_profit) AS total_net_profit,
    SUM(asales.total_quantity_sold) AS total_quantity_sold
FROM 
    item it
LEFT JOIN 
    AggregateSales asales ON it.i_item_sk = asales.ws_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (SELECT 
                                                  c.c_current_cdemo_sk 
                                               FROM 
                                                  customer c 
                                               WHERE 
                                                  c.c_customer_sk = (SELECT 
                                                                      ws.ws_bill_customer_sk 
                                                                    FROM 
                                                                      web_sales ws 
                                                                    WHERE 
                                                                      ws.ws_item_sk = it.i_item_sk 
                                                                      LIMIT 1)
                                               )
GROUP BY 
    it.i_item_id, 
    it.i_item_desc, 
    cd.cd_gender
HAVING 
    SUM(asales.total_net_profit) > 1000
ORDER BY 
    total_net_profit DESC;
