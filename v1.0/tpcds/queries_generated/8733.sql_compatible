
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        MAX(ws.ws_net_profit) AS max_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.bill_customer_sk
),
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT sd.bill_customer_sk) AS customer_count,
        AVG(sd.total_sales) AS avg_sales_per_customer,
        AVG(sd.total_orders) AS avg_orders_per_customer,
        SUM(sd.total_discount) AS total_discounts_given,
        SUM(sd.max_profit) AS total_max_profit
    FROM SalesData sd
    JOIN customer c ON sd.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ds.cd_gender,
    ds.customer_count,
    ds.avg_sales_per_customer,
    ds.avg_orders_per_customer,
    ds.total_discounts_given,
    ds.total_max_profit
FROM DemographicStats ds
ORDER BY ds.customer_count DESC, ds.avg_sales_per_customer DESC;
