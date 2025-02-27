
WITH AddressDetails AS (
    SELECT
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM
        customer_address
    WHERE
        ca_state = 'CA'
),
CustomerModels AS (
    SELECT
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        ws_ship_date_sk
    FROM
        web_sales
    WHERE
        ws_sales_price > 100
),
CustomerSales AS (
    SELECT
        cm.full_name,
        cm.cd_gender,
        sd.ws_order_number,
        sd.ws_sales_price,
        sd.ws_net_profit,
        dd.d_date AS sale_date
    FROM
        CustomerModels cm
    JOIN
        SalesData sd ON cm.c_customer_id = sd.ws_order_number
    JOIN
        date_dim dd ON sd.ws_ship_date_sk = dd.d_date_sk
)
SELECT
    ad.full_address,
    cs.full_name,
    cs.cd_gender,
    SUM(cs.ws_sales_price) AS total_sales,
    AVG(cs.ws_net_profit) AS avg_net_profit,
    COUNT(cs.ws_order_number) AS order_count
FROM
    AddressDetails ad
JOIN
    CustomerSales cs ON ad.ca_zip = LEFT(cs.full_name, 5)
GROUP BY
    ad.full_address,
    cs.full_name,
    cs.cd_gender
ORDER BY
    total_sales DESC;
