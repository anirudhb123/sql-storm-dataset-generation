WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_order_number
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_quantity,
    sd.total_profit,
    rd.total_return_quantity,
    rd.total_return_amount
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    SalesData sd ON sd.ws_item_sk = RANDOM()  
LEFT JOIN 
    ReturnData rd ON rd.wr_item_sk = sd.ws_item_sk
ORDER BY 
    ad.full_address, cd.full_name;