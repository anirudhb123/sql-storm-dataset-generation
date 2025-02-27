
WITH SalesData AS (
    SELECT
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_order_number,
        sd.cd_gender,
        sd.cd_marital_status,
        sd.cd_purchase_estimate,
        sd.cd_credit_rating,
        cnty.ca_county,
        cnty.ca_state,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics sd ON c.c_current_cdemo_sk = sd.cd_demo_sk
    JOIN customer_address cnty ON c.c_current_addr_sk = cnty.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_order_number,
        sd.cd_gender,
        sd.cd_marital_status,
        sd.cd_purchase_estimate,
        sd.cd_credit_rating,
        cnty.ca_county,
        cnty.ca_state,
        d.d_year
),
AggregatedSales AS (
    SELECT
        web_site_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM SalesData
    GROUP BY web_site_sk, cd_gender, cd_marital_status
)
SELECT
    web_site_sk,
    cd_gender,
    cd_marital_status,
    order_count,
    total_quantity,
    total_sales,
    max_purchase_estimate,
    CASE
        WHEN total_sales > 100000 THEN 'High Performer'
        WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM AggregatedSales
ORDER BY total_sales DESC;
