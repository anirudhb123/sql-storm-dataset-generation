
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        MIN(ws_sold_date_sk) AS first_sale_date,
        MAX(ws_sold_date_sk) AS last_sale_date
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_summary AS (
    SELECT
        c.c_current_cdemo_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders_customer,
        SUM(ws_net_paid_inc_tax) AS total_sales_customer
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_current_cdemo_sk
),
sales_distribution AS (
    SELECT
        ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ss.total_sales) AS income_band_sales
    FROM
        sales_summary ss
    JOIN
        customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = ss.ws_item_sk)
    JOIN
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY
        ib_income_band_sk
),
final_report AS (
    SELECT
        ss.ws_item_sk,
        ss.total_orders,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_order_value,
        cs.total_orders_customer,
        cs.total_sales_customer,
        ib.ib_income_band_sk,
        ib.customer_count,
        ib.income_band_sales
    FROM
        sales_summary ss
    LEFT JOIN
        customer_summary cs ON cs.c_current_cdemo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = ss.ws_item_sk)
    LEFT JOIN
        sales_distribution ib ON ib.ws_item_sk = ss.ws_item_sk
)
SELECT 
    ws_item_sk,
    total_orders,
    total_quantity,
    total_sales,
    avg_order_value,
    total_orders_customer,
    total_sales_customer,
    ib_income_band_sk,
    customer_count,
    income_band_sales
FROM 
    final_report
WHERE 
    total_sales > 1000
ORDER BY
    total_sales DESC
LIMIT 100;
