
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
Benchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ii.i_item_desc,
        ii.i_current_price,
        si.total_sales,
        si.total_profit
    FROM 
        CustomerInfo ci
    JOIN 
        SalesInfo si ON ci.c_customer_sk IN (
            SELECT 
                ws.ws_bill_customer_sk 
            FROM 
                web_sales ws 
            WHERE 
                ws.ws_item_sk IN (
                    SELECT 
                        si.ws_item_sk
                    FROM 
                        web_sales si
                )
        )
    JOIN 
        ItemInfo ii ON ii.i_item_sk = si.ws_item_sk
    ORDER BY 
        total_profit DESC
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    i_item_desc,
    i_current_price,
    total_sales,
    total_profit
FROM 
    Benchmark
WHERE 
    total_profit > 1000
ORDER BY 
    total_profit DESC;
