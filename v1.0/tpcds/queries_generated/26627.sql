
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateFiltered AS (
    SELECT 
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d 
    WHERE 
        d.d_year = 2023 AND (d.d_month_seq BETWEEN 1 AND 12) 
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_date_sk,
        cd.full_name,
        cd.ca_city,
        cd.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_id
),
ProcessedData AS (
    SELECT 
        sd.full_name,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price) AS total_sales_price,
        SUM(sd.ws_net_profit) AS total_net_profit,
        dd.d_date
    FROM 
        SalesData sd
    JOIN 
        DateFiltered dd ON sd.ws_ship_date_sk = dd.d_date
    GROUP BY 
        sd.full_name, dd.d_date
)
SELECT 
    CONCAT('Customer: ', pd.full_name) AS detailed_info,
    pd.total_quantity,
    pd.total_sales_price,
    pd.total_net_profit,
    MAX(pd.d_date) AS last_purchase_date
FROM 
    ProcessedData pd
GROUP BY 
    pd.full_name, pd.total_quantity, pd.total_sales_price, pd.total_net_profit
ORDER BY 
    pd.total_net_profit DESC, pd.total_quantity DESC;
