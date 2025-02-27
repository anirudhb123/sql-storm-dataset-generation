
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year,
        cs.cs_quantity,
        cd.cd_gender,
        ca.ca_state
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        d.d_year,
        cd.cd_gender,
        ca.ca_state
),
RankedSales AS (
    SELECT
        sd.*,
        RANK() OVER (PARTITION BY sd.d_year, sd.ca_state ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
)

SELECT
    rs.d_year,
    rs.ca_state,
    COUNT(DISTINCT rs.ws_item_sk) AS item_count,
    SUM(rs.total_quantity) AS total_quantity_sold,
    SUM(rs.total_sales) AS total_sales_value,
    AVG(rs.total_discount) AS average_discount,
    MAX(rs.sales_rank) AS highest_sales_rank
FROM
    RankedSales rs
WHERE
    rs.sales_rank <= 10
GROUP BY
    rs.d_year,
    rs.ca_state
ORDER BY
    rs.d_year ASC,
    total_sales_value DESC;
