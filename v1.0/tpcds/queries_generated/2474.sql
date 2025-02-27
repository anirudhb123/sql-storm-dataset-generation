
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CD.cd_gender,
        CD.cd_marital_status,
        CA.ca_country
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    LEFT JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    WHERE 
        CA.ca_country IS NOT NULL AND 
        CD.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_id, CD.cd_gender, CD.cd_marital_status, CA.ca_country
),
RankedSales AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        cd_gender,
        cd_marital_status,
        ca_country,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
SignificantSales AS (
    SELECT 
        r.c_customer_id,
        r.total_sales,
        r.order_count,
        r.sales_rank,
        r.cd_gender,
        r.cd_marital_status,
        r.ca_country,
        CASE 
            WHEN r.order_count > 5 THEN 'High Frequency' 
            WHEN r.order_count BETWEEN 3 AND 5 THEN 'Medium Frequency'
            ELSE 'Low Frequency' 
        END AS frequency_category
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
)

SELECT 
    ss.c_customer_id,
    ss.total_sales,
    ss.order_count,
    ss.sales_rank,
    ss.cd_gender,
    ss.cd_marital_status,
    ss.ca_country,
    ss.frequency_category,
    COUNT(*) OVER (PARTITION BY ss.frequency_category) AS freq_category_count,
    COALESCE(NULLIF(ss.total_sales, 0), 'No Sales') AS sales_summary
FROM 
    SignificantSales ss
ORDER BY 
    ss.frequency_category, ss.total_sales DESC;
