
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),

sales_data AS (
    SELECT 
        SUM(ws.ws_sales_price) AS total_sales,
        ws.ws_bill_customer_sk,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk, DATE(d.d_date)
),

returns_data AS (
    SELECT 
        SUM(wr.wr_return_amt) AS total_returns,
        wr.wr_returning_customer_sk,
        DATE(d.d_date) AS return_date
    FROM 
        web_returns wr
    JOIN 
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY 
        wr.wr_returning_customer_sk, DATE(d.d_date)
)

SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    SUM(sd.total_sales) AS total_sales_amount,
    SUM(rd.total_returns) AS total_returns_amount,
    NULLIF(SUM(sd.total_sales), 0) AS net_sales,
    ci.hd_income_band_sk,
    ci.hd_buy_potential,
    ci.hd_dep_count
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
LEFT JOIN 
    returns_data rd ON ci.c_customer_id = rd.wr_returning_customer_sk
GROUP BY 
    ci.c_customer_id, ci.c_first_name, ci.c_last_name, ci.cd_gender, 
    ci.cd_marital_status, ci.cd_education_status, ci.hd_income_band_sk, 
    ci.hd_buy_potential, ci.hd_dep_count
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
