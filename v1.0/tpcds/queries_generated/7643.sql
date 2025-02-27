
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2415 AND 2420
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk, 
        i.i_item_desc, 
        sd.total_quantity, 
        sd.total_net_profit, 
        sd.order_count
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    ORDER BY 
        sd.total_net_profit DESC
    LIMIT 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk 
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_customer_id IN (
            SELECT DISTINCT 
                ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_sold_date_sk BETWEEN 2415 AND 2420
        )
)
SELECT 
    ts.ws_item_sk, 
    ts.i_item_desc, 
    ts.total_quantity, 
    ts.total_net_profit, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
FROM 
    TopSales ts
JOIN 
    CustomerDemographics cd ON cd.cd_income_band_sk = i.i_item_sk
JOIN 
    income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    total_net_profit DESC;
