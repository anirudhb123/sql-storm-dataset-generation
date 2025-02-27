
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_orders,
        SUM(rs.ws_sales_price) AS total_sales,
        MAX(rs.ws_sales_price) AS max_sales_price,
        SUM(CASE WHEN rs.rank_sales_price <= 5 THEN 1 ELSE 0 END) AS top_sales_count
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_item_sk
),
CustomerInsights AS (
    SELECT 
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        d.d_year,
        COUNT(DISTINCT CASE WHEN d.d_dow IN (1, 7) THEN cu.c_customer_id END) AS weekend_customers,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_estimate,
        MAX(cd.cd_credit_rating) AS max_rating
    FROM 
        customer cu
    JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON cu.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cu.c_birth_year IS NOT NULL
    GROUP BY 
        cu.c_customer_sk, cu.c_first_name, cu.c_last_name, d.d_year
),
SalesWithDemographics AS (
    SELECT 
        ss.*,
        ci.avg_estimate,
        ci.max_rating
    FROM 
        SalesSummary ss
    LEFT JOIN 
        CustomerInsights ci ON ss.ws_item_sk = ci.c_customer_sk
)
SELECT 
    swd.ws_item_sk,
    swd.total_orders,
    swd.total_sales,
    swd.avg_estimate,
    swd.max_rating,
    CASE 
        WHEN swd.total_sales > 10000 THEN 'High Sales'
        WHEN swd.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    COALESCE(CONVERT(VARCHAR(10), STRING_AGG(ci.c_first_name + ' ' + ci.c_last_name, ', ') WITHIN GROUP (ORDER BY ci.c_first_name)), 'No Customers') AS customer_names
FROM 
    SalesWithDemographics swd
JOIN 
    customer cu ON cu.c_customer_sk IN (SELECT DISTINCT c_customer_sk FROM CustomerInsights)
WHERE 
    swd.total_orders > 1
GROUP BY 
    swd.ws_item_sk, swd.total_orders, swd.total_sales, swd.avg_estimate, swd.max_rating
ORDER BY 
    swd.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
