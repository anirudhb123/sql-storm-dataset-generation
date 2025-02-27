
WITH AddressInfo AS (
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
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_date AS sale_date,
        d.d_month_seq,
        w.w_warehouse_name
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
),
AggregatedSales AS (
    SELECT 
        ci.full_name,
        ai.full_address,
        si.warehouse_name,
        SUM(si.ws_net_profit) AS total_profit,
        COUNT(si.ws_order_number) AS total_orders,
        AVG(si.ws_sales_price) AS avg_sales_price
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ai.full_address, si.warehouse_name
)
SELECT 
    full_name,
    full_address,
    warehouse_name,
    total_profit,
    total_orders,
    avg_sales_price,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM 
    AggregatedSales
WHERE 
    total_orders > 10
ORDER BY 
    total_profit DESC, total_orders DESC;
