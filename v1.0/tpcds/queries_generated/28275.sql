
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, 
        ws.ws_sold_date_sk
),
ReturnData AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ca_city,
    cd.ca_state,
    SUM(sd.total_sales) AS total_sales,
    SUM(sd.total_profit) AS total_profit,
    COALESCE(SUM(rd.total_return_amount), 0) AS total_returns,
    COALESCE(SUM(rd.total_returns), 0) AS total_return_count,
    cd.full_address
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_id = sd.ws_order_number
LEFT JOIN 
    ReturnData rd ON sd.ws_order_number = rd.wr_order_number
GROUP BY 
    cd.full_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.ca_city, 
    cd.ca_state, 
    cd.full_address
ORDER BY 
    total_sales DESC
LIMIT 100;
