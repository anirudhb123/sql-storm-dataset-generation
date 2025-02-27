
WITH RECURSIVE demographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
), sales_summary AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MIN(d_date) AS first_order_date,
        MAX(d_date) AS last_order_date
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws_bill_cdemo_sk
), enriched_sales AS (
    SELECT
        ss.ws_bill_cdemo_sk,
        ss.total_sales,
        ss.order_count,
        ss.first_order_date,
        ss.last_order_date,
        COALESCE(d.cd_marital_status, 'Unknown') AS marital_status,
        CASE WHEN d.cd_purchase_estimate > 1000 THEN 'High Value'
             WHEN d.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
             ELSE 'Low Value' END AS customer_value_category
    FROM sales_summary ss
    LEFT JOIN demographics d ON ss.ws_bill_cdemo_sk = d.cd_demo_sk AND d.rank = 1
), return_metrics AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
), combined_metrics AS (
    SELECT
        es.ws_bill_cdemo_sk,
        es.total_sales,
        es.order_count,
        es.first_order_date,
        es.last_order_date,
        es.marital_status,
        es.customer_value_category,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.return_count, 0) AS return_count,
        (CASE WHEN es.total_sales > 0 THEN (COALESCE(r.total_returns, 0) / es.order_count) * 100 ELSE 0 END) AS return_rate
    FROM enriched_sales es
    LEFT JOIN return_metrics r ON es.ws_bill_cdemo_sk = r.sr_customer_sk
)
SELECT
    cm.ws_bill_cdemo_sk,
    cm.total_sales,
    cm.order_count,
    cm.first_order_date,
    cm.last_order_date,
    cm.marital_status,
    cm.customer_value_category,
    cm.total_returns,
    cm.return_count,
    cm.return_rate
FROM combined_metrics cm
WHERE cm.return_rate IS NOT NULL
ORDER BY cm.total_sales DESC, cm.return_count ASC
LIMIT 10;
