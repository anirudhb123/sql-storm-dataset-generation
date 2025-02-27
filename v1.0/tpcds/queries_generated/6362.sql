
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(sd.total_quantity) AS total_quantity_bought,
    SUM(sd.total_profit) AS total_profits
FROM 
    CustomerData cd
JOIN 
    SalesData sd ON cd.c_customer_sk = (SELECT r.ws_bill_customer_sk FROM web_sales r WHERE r.ws_item_sk = sd.ws_item_sk LIMIT 1)
GROUP BY 
    cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_profits DESC
LIMIT 50;
