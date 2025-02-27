
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_data AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
summary AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales,
        cd.hd_buy_potential,
        cd.hd_dep_count,
        cd.hd_vehicle_count
    FROM 
        customer_data cd
        LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
        LEFT JOIN returns_data rd ON cd.c_customer_sk = rd.wr_returning_customer_sk
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.cd_marital_status,
    s.total_sales,
    s.total_returns,
    s.net_sales,
    s.hd_buy_potential
FROM 
    summary s
WHERE 
    s.net_sales > 1000
ORDER BY 
    s.net_sales DESC
LIMIT 50;
