
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateInfo AS (
    SELECT 
        d.d_date,
        d.d_month_seq,
        d.d_year,
        d.d_day_name,
        d.d_weekend
    FROM 
        date_dim AS d
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        s.s_store_id,
        s.s_store_name
    FROM 
        web_sales AS ws
    JOIN 
        store AS s ON ws.ws_store_sk = s.s_store_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    di.d_date,
    di.d_day_name,
    si.s_store_name,
    COUNT(si.ws_item_sk) AS total_sales,
    SUM(si.ws_net_profit) AS total_profit,
    COUNT(DISTINCT si.ws_item_sk) AS unique_items_sold
FROM 
    CustomerInfo AS ci
JOIN 
    DateInfo AS di ON di.d_date BETWEEN '2023-01-01' AND '2023-12-31'
JOIN 
    SalesInfo AS si ON ci.c_customer_id = si.ws_bill_customer_sk
WHERE 
    ci.c_birth_day = EXTRACT(DAY FROM di.d_date)
    AND ci.c_birth_month = EXTRACT(MONTH FROM di.d_date)
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state, di.d_date, di.d_day_name, si.s_store_name
ORDER BY 
    total_profit DESC;
