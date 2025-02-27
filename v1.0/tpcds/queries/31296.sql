
WITH RECURSIVE Forecasted_Sales AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk + 1,
        SUM(ws_quantity) * 1.05 AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY (ws_sold_date_sk + 1) ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk <= (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_sold_date_sk
    HAVING SUM(ws_quantity) > 0
),
Sales_Summary AS (
    SELECT 
        d_year,
        SUM(total_sales) AS yearly_sales,
        AVG(total_sales) AS avg_daily_sales
    FROM 
        (SELECT 
            d.d_year,
            f.total_sales
        FROM 
            date_dim d
        INNER JOIN 
            Forecasted_Sales f ON d.d_date_sk = f.ws_sold_date_sk) AS daily_sales
    GROUP BY d_year
),
Customer_Segment AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    s.yearly_sales,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    CASE 
        WHEN cs.avg_purchase_estimate IS NULL THEN 'No Data' 
        ELSE ROUND((s.yearly_sales / cs.avg_purchase_estimate), 2)::VARCHAR
    END AS sales_to_estimate_ratio
FROM 
    Sales_Summary s
LEFT JOIN 
    Customer_Segment cs ON s.yearly_sales > cs.avg_purchase_estimate
WHERE 
    s.yearly_sales > 1000000
ORDER BY 
    s.yearly_sales DESC, cs.customer_count DESC;
