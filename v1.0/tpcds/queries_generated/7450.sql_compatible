
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d.d_year AS sales_year,
        i.i_category AS item_category,
        c.cd_gender AS customer_gender,
        ca.ca_state AS customer_state,
        w.w_warehouse_name AS warehouse_name
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.ws_item_sk,
        d.d_year,
        i.i_category,
        c.cd_gender,
        ca.ca_state,
        w.w_warehouse_name
),
RankedSales AS (
    SELECT
        sd.*,
        RANK() OVER (PARTITION BY sd.sales_year, sd.item_category ORDER BY sd.total_quantity_sold DESC) AS sales_rank
    FROM
        SalesData sd
)
SELECT
    rs.sales_year,
    rs.item_category,
    rs.customer_gender,
    rs.customer_state,
    SUM(rs.total_quantity_sold) AS total_quantity,
    SUM(rs.total_net_paid) AS total_sales,
    SUM(rs.total_discount) AS total_discounts,
    COUNT(*) AS number_of_sales
FROM
    RankedSales rs
WHERE
    rs.sales_rank <= 10
GROUP BY
    rs.sales_year,
    rs.item_category,
    rs.customer_gender,
    rs.customer_state
ORDER BY
    rs.sales_year, total_sales DESC;
