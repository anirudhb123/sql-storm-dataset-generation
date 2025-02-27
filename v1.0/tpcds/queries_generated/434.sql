
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        i_current_price
    FROM
        item
),
CustomerInfo AS (
    SELECT
        c_customer_sk,
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status
    FROM
        customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
DateRange AS (
    SELECT
        d_date_sk,
        d_year,
        d_month_seq,
        DENSE_RANK() OVER (ORDER BY d_year, d_month_seq) AS month_rank
    FROM
        date_dim
    WHERE
        d_date BETWEEN '2022-01-01' AND '2022-12-31'
)
SELECT
    di.d_year,
    di.month_rank,
    COUNT(DISTINCT ci.c_customer_sk) AS total_customers,
    SUM(sd.total_quantity) AS total_quantity_sold,
    SUM(sd.total_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT id.i_product_name, ', ') AS sold_products,
    AVG(id.i_current_price) AS avg_product_price
FROM
    SalesData sd
JOIN DateRange di ON di.d_date_sk = sd.ws_sold_date_sk
JOIN CustomerInfo ci ON ci.c_customer_sk = sd.ws_bill_customer_sk
JOIN ItemDetails id ON id.i_item_sk = sd.ws_item_sk
GROUP BY
    di.d_year, di.month_rank
ORDER BY
    di.d_year DESC, di.month_rank;
