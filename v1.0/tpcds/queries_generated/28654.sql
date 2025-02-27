
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer 
    JOIN 
        customer_demographics 
    ON 
        c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_order_number,
        ws_web_page_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        d_year,
        d_month_seq,
        d_day_name
    FROM 
        web_sales
    JOIN 
        date_dim 
    ON 
        ws_sold_date_sk = d_date_sk
),
RankedSales AS (
    SELECT 
        ws_order_number,
        full_name,
        full_address,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY d_year, d_month_seq ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        SalesData 
    JOIN 
        CustomerInfo 
    ON 
        ws_bill_customer_sk = c_customer_sk
    JOIN 
        AddressInfo 
    ON 
        c_current_addr_sk = ca_address_sk
)
SELECT 
    full_name,
    full_address,
    SUM(ws_sales_price * ws_quantity) AS total_sales,
    AVG(ws_net_profit) AS average_net_profit
FROM 
    RankedSales
WHERE 
    profit_rank <= 10
GROUP BY 
    full_name, full_address
ORDER BY 
    total_sales DESC;
