
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        household_demographics h ON c.c_customer_sk = h.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_data AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
aggregated_data AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        sd.total_sales,
        rd.total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_revenue
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_id = sd.ws_bill_customer_sk
    LEFT JOIN 
        returns_data rd ON ci.c_customer_id = rd.wr_returning_customer_sk
)
SELECT 
    ad.c_first_name,
    ad.c_last_name,
    ad.total_sales,
    ad.total_returns,
    ad.net_revenue,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country
FROM 
    aggregated_data ad
WHERE 
    ad.net_revenue > 1000
ORDER BY 
    ad.net_revenue DESC
LIMIT 100;
