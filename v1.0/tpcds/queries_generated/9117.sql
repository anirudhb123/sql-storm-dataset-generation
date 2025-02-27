
WITH sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        c.cd_marital_status
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        ws.ws_item_sk,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        c.cd_marital_status
),
sales_ranking AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.average_sales_price,
        sd.min_sales_price,
        sd.max_sales_price,
        RANK() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        sales_data sd
)
SELECT
    sr.ws_item_sk,
    sr.total_quantity,
    sr.total_sales,
    sr.average_sales_price,
    sr.min_sales_price,
    sr.max_sales_price,
    sr.sales_rank,
    c.ca_city,
    c.ca_state
FROM
    sales_ranking sr
JOIN
    item i ON sr.ws_item_sk = i.i_item_sk
JOIN
    customer_address c ON i.i_item_sk = c.ca_address_sk
WHERE
    sr.sales_rank <= 10
ORDER BY
    sr.d_year DESC,
    sr.d_month_seq DESC,
    sr.sales_rank;
