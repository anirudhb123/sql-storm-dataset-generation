
WITH sales_data AS (
    SELECT
        w.warehouse_name,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ship_customer_sk) AS unique_customers,
        AVG(ws_ext_discount_amt) AS avg_discount,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid,
        d.d_year AS sales_year
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    JOIN
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        w.warehouse_name, d.d_year
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, 
        c.c_preferred_cust_flag, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        cd.cd_dep_count
)
SELECT
    sd.warehouse_name,
    sd.sales_year,
    sd.total_net_profit,
    sd.unique_customers,
    sd.avg_discount,
    sd.avg_net_paid,
    COUNT(DISTINCT cd.c_customer_id) AS total_customers,
    SUM(cd.total_orders) AS cumulative_orders
FROM
    sales_data sd
LEFT JOIN
    customer_data cd ON sd.unique_customers = cd.total_orders
GROUP BY
    sd.warehouse_name, 
    sd.sales_year, 
    sd.total_net_profit, 
    sd.unique_customers, 
    sd.avg_discount, 
    sd.avg_net_paid
ORDER BY
    sd.sales_year DESC, 
    sd.total_net_profit DESC;
