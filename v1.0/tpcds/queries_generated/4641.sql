
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
WebSiteTopSales AS (
    SELECT 
        w.web_site_id,
        w.web_name,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        web_site w ON rs.web_site_sk = w.web_site_sk
    WHERE 
        rs.rank <= 5
),
CustomerDemographic AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS gender,
        cd.cd_marital_status AS marital_status,
        ib.ib_income_band_sk AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ws.web_name,
    wts.total_quantity,
    wts.total_profit,
    cd.gender,
    cd.marital_status,
    COALESCE(cd.income_band, -1) AS income_band,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    WebSiteTopSales wts ON ws.ws_web_site_sk = wts.web_site_sk
JOIN 
    CustomerDemographic cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    wts.total_profit > 1000
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ws.web_name, 
    wts.total_quantity, wts.total_profit, cd.gender, cd.marital_status, cd.income_band
ORDER BY 
    total_profit DESC
LIMIT 50;
