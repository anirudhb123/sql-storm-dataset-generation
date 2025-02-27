
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateRange AS (
    SELECT 
        d.d_date_id,
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        d.d_date_id,
        d.d_year
    FROM web_sales ws
    JOIN DateRange d ON ws.ws_sold_date_sk = d.d_date_id
),
AggregatedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(DISTINCT sd.ws_order_number) AS order_count
    FROM CustomerDetails c
    JOIN SalesData sd ON c.c_customer_id = sd.ws_order_number
    GROUP BY c.c_customer_id
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    asales.total_quantity,
    asales.total_sales,
    asales.total_profit,
    asales.order_count
FROM CustomerDetails cd
JOIN AggregatedSales asales ON cd.c_customer_id = asales.c_customer_id
ORDER BY asales.total_sales DESC, asales.total_profit DESC
LIMIT 100;
