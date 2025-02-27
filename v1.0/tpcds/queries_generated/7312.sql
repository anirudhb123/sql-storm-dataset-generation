
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_country,
        d.d_year,
        d.d_quarter_seq
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 AND ws.ws_quantity > 1
),
CustomerAggregate AS (
    SELECT 
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM SalesData
    GROUP BY ca.ca_country, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    country,
    gender,
    marital_status,
    total_sales,
    total_quantity,
    unique_items_sold,
    RANK() OVER (PARTITION BY country ORDER BY total_sales DESC) AS sales_rank
FROM CustomerAggregate
ORDER BY country, sales_rank;
