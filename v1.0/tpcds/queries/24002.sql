
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_income,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_paid) DESC) AS ranking
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
initialization AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') 
        AND cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        ca_city
),
date_wise_sales AS (
    SELECT
        d.d_date,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_net_income, 0.00) AS total_income,
        COALESCE(ROUND(NULLIF(ss.total_net_income, 0) / NULLIF(ss.total_quantity, 0) * 100, 2), 0) AS average_revenue_per_item
    FROM 
        date_dim d
    LEFT JOIN 
        sales_summary ss ON d.d_date_sk = ss.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
final_report AS (
    SELECT 
        dw.d_date,
        dw.total_quantity,
        dw.total_income,
        dw.average_revenue_per_item,
        i.ca_city,
        i.customer_count,
        i.max_purchase_estimate
    FROM 
        date_wise_sales dw
    JOIN 
        initialization i ON dw.total_quantity > i.customer_count
)
SELECT 
    fr.d_date,
    fr.total_quantity,
    fr.total_income,
    fr.average_revenue_per_item,
    fr.ca_city,
    fr.customer_count,
    fr.max_purchase_estimate,
    CASE 
        WHEN fr.average_revenue_per_item > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_indicator
FROM 
    final_report fr
WHERE 
    fr.customer_count > 10
ORDER BY 
    fr.total_income DESC,
    fr.d_date ASC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM date_wise_sales) - 100;
