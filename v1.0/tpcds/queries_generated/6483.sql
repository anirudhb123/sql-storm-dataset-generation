
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk 
    WHERE 
        d.d_year = 2023 
        AND i.i_category = 'Beverages'
    GROUP BY 
        ws.web_site_id
), 
CustomerCategory AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN h.hd_income_band_sk IS NOT NULL THEN h.hd_income_band_sk
            ELSE -1 
        END AS income_band
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
), 
SalesAnalysis AS (
    SELECT 
        s.web_site_id,
        cc.cd_gender,
        cc.cd_marital_status,
        cc.cd_education_status,
        ca.income_band,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_orders) AS total_orders,
        AVG(sd.avg_net_profit) AS avg_net_profit
    FROM 
        SalesData sd 
    JOIN 
        CustomerCategory cc ON sd.web_site_id = cc.c_customer_id
    JOIN 
        web_site s ON sd.web_site_id = s.web_site_id
    GROUP BY 
        s.web_site_id, cc.cd_gender, cc.cd_marital_status, cc.cd_education_status, ca.income_band
)
SELECT 
    web_site_id,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    income_band,
    SUM(total_sales) AS total_sales,
    SUM(total_orders) AS total_orders,
    AVG(avg_net_profit) AS avg_net_profit
FROM 
    SalesAnalysis
GROUP BY 
    web_site_id, cd_gender, cd_marital_status, cd_education_status, income_band
ORDER BY 
    total_sales DESC
LIMIT 10;
