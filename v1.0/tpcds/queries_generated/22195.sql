
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_quantity DESC) AS sales_rank,
        ws.ws_order_number,
        CASE 
            WHEN ws.ws_sales_price < 0 THEN 'Negative Price'
            WHEN ws.ws_sales_price IS NULL THEN 'Unknown Price'
            ELSE 'Valid Price'
        END AS price_status
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), CTE_Summary AS (
    SELECT
        r.web_site_sk,
        SUM(r.ws_sales_price) AS total_sales,
        COUNT(*) AS total_orders,
        AVG(r.ws_sales_price) AS avg_sales_price
    FROM RankedSales r
    WHERE r.sales_rank = 1 AND r.price_status = 'Valid Price'
    GROUP BY r.web_site_sk
), CustomersAndDemographics AS (
    SELECT
        c.c_customer_id,
        d.cd_gender,
        COUNT(DISTINCT s.ss_ticket_number) AS store_sales_count,
        SUM(s.ss_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE c.c_birth_year <= 1980
    GROUP BY c.c_customer_id, d.cd_gender
), FinalResults AS (
    SELECT
        cs.web_site_sk,
        COALESCE(cs.total_sales, 0) AS total_sales,
        COALESCE(cs.total_orders, 0) AS total_orders,
        ca.c_customer_id,
        ca.cd_gender,
        ca.store_sales_count,
        ca.total_spent,
        CASE 
            WHEN cs.total_sales > 1000 THEN 'High Performer'
            WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM CTE_Summary cs
    FULL OUTER JOIN CustomersAndDemographics ca ON cs.web_site_sk IS NOT NULL AND ca.store_sales_count > 0
)
SELECT
    f.web_site_sk,
    f.total_sales,
    f.total_orders,
    f.c_customer_id,
    f.cd_gender,
    f.store_sales_count,
    f.total_spent,
    f.performance_category,
    CASE 
        WHEN f.total_spent IS NOT NULL AND f.total_spent > 0 THEN (f.total_sales / NULLIF(f.total_spent, 0))
        ELSE NULL
    END AS sales_to_spending_ratio
FROM FinalResults f
WHERE f.performance_category IN ('High Performer', 'Medium Performer')
ORDER BY f.total_sales DESC, f.total_orders DESC;
