
WITH customer_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT wr.wr_order_number) AS returns_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
income_analysis AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(ca.ca_zip IS NOT NULL) AS address_count,
        AVG(ca.ca_gmt_offset) AS average_gmt_offset
    FROM 
        household_demographics hd
    JOIN 
        customer c ON c.c_current_hdemo_sk = hd.hd_demo_sk 
    JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    cust.c_customer_id,
    cust.cd_gender,
    cust.cd_marital_status,
    cust.cd_education_status,
    cust.total_spent,
    cust.total_orders,
    cust.average_profit,
    cust.returns_count,
    income.hd_income_band_sk,
    income.address_count,
    income.average_gmt_offset
FROM 
    customer_analysis cust
JOIN 
    income_analysis income ON cust.c_customer_id BETWEEN 100 AND 200
WHERE 
    cust.total_spent > 5000
ORDER BY 
    cust.total_spent DESC
LIMIT 100;
