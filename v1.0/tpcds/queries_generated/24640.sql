
WITH RecursiveSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales
    FROM 
        store_sales  
    GROUP BY 
        ss_customer_sk

    UNION ALL

    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_profit,
        COUNT(DISTINCT wr_order_number) AS total_sales
    FROM 
        web_returns  
    WHERE 
        wr_net_loss > 0
    GROUP BY 
        wr_returning_customer_sk  
)
, CustomerAnalysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(SUM(rs.total_profit), 0) AS net_profit,
        COALESCE(SUM(rs.total_sales), 0) AS sales_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        RecursiveSales rs ON c.c_customer_sk = rs.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ca.city,
    ca.state,
    MAX(ca.zip) AS zip_with_max AS max_zip,
    c.customer_id,
    c.gender,
    COALESCE(c.net_profit, -1) AS net_profit,
    c.sales_count,
    CASE 
        WHEN c.net_profit <= 0 THEN 'Low Performer'
        WHEN c.sales_count > 100 THEN 'High Performer'
        ELSE 'Moderate Performer'
    END AS performance_band
FROM 
    CustomerAnalysis c
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_customer_sk
LEFT JOIN 
    income_band ib ON (c.net_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound)
WHERE 
    c.sales_count IS NULL OR 
    (c.gender = 'F' AND c.net_profit > 0) 
ORDER BY 
    c.sales_count DESC, 
    net_profit ASC
FETCH FIRST 10 ROWS ONLY;
