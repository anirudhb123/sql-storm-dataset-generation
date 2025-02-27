
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        c.c_customer_id
), RankedSales AS (
    SELECT 
        c.customer_id,
        c.total_spent,
        c.order_count,
        RANK() OVER (ORDER BY c.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales c
), Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(i.ib_lower_bound, 0) AS income_band_lower,
        COALESCE(i.ib_upper_bound, 9999999) AS income_band_upper
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band i ON hd.hd_income_band_sk = i.ib_income_band_sk
), FinalReport AS (
    SELECT 
        rs.customer_id,
        rs.total_spent,
        rs.order_count,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        CASE 
            WHEN rs.sales_rank <= 10 THEN 'Top 10 Customers'
            WHEN rs.sales_rank BETWEEN 11 AND 50 THEN 'Top 50 Customers'
            ELSE 'Others'
        END AS customer_category
    FROM 
        RankedSales rs
    JOIN 
        Demographics d ON rs.customer_id = d.cd_demo_sk
)
SELECT 
    f.customer_category,
    COUNT(*) AS customer_count,
    AVG(f.total_spent) AS average_spent,
    SUM(f.order_count) AS total_orders,
    MAX(f.total_spent) AS max_spent,
    MIN(f.total_spent) AS min_spent
FROM 
    FinalReport f
GROUP BY 
    f.customer_category
UNION ALL
SELECT 
    'Unmatched' AS customer_category,
    COUNT(c.c_customer_id),
    AVG(0) AS average_spent,
    SUM(0) AS total_orders,
    MAX(NULL) AS max_spent,
    MIN(NULL) AS min_spent
FROM 
    customer c
WHERE 
    c.c_customer_id NOT IN (SELECT customer_id FROM RankedSales)
ORDER BY 
    FIELD(customer_category, 'Top 10 Customers', 'Top 50 Customers', 'Others', 'Unmatched');
