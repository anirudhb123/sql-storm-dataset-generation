
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, 1 AS level
    FROM date_dim
    WHERE d_year >= 2020
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, dh.level + 1 AS level
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_year = dh.d_year + 1
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        SUM(ws_quantity) AS total_units_sold,
        AVG(ws_sales_price) AS average_sales_price
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
FilteredSales AS (
    SELECT 
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS transaction_count,
        s.s_store_name,
        i.i_item_desc
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_current_price > 10.00
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, s.s_store_name, i.i_item_desc
)
SELECT 
    dh.d_year,
    COUNT(DISTINCT cs.ws_bill_customer_sk) AS total_customers,
    SUM(cs.total_revenue) AS total_revenue,
    AVG(cs.average_sales_price) AS average_sales_price,
    COALESCE(SUM(fs.total_net_profit), 0) AS total_store_profit,
    STRING_AGG(DISTINCT CONCAT(cu.cd_gender, ' - ', cu.cd_marital_status), ', ') AS demographic_summary
FROM DateHierarchy dh
LEFT JOIN SalesSummary cs ON cs.total_orders > 10
LEFT JOIN FilteredSales fs ON fs.ss_store_sk IN (SELECT DISTINCT s_store_sk FROM store)
LEFT JOIN CustomerDemographics cu ON cs.ws_bill_customer_sk = cu.c_customer_sk
WHERE dh.level <= 3
GROUP BY dh.d_year
ORDER BY dh.d_year DESC;
