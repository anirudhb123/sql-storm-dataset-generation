
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
Top_Sales AS (
    SELECT 
        d.d_date,
        sc.total_sales
    FROM 
        date_dim d
    JOIN 
        Sales_CTE sc ON d.d_date_sk = sc.ws_sold_date_sk
    WHERE 
        sc.sales_rank <= 10
),
Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.web_site_sk) AS website_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT c.c_email_address, ', ') AS email_list
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ts.d_date,
    ts.total_sales,
    cs.c_customer_sk,
    cs.website_count,
    cs.avg_purchase_estimate,
    (CASE 
         WHEN cs.avg_purchase_estimate IS NULL THEN 'Unknown'
         ELSE 
             (CASE 
                  WHEN cs.avg_purchase_estimate >= 1000 THEN 'High Value'
                  WHEN cs.avg_purchase_estimate >= 500 THEN 'Medium Value'
                  ELSE 'Low Value' 
              END)
     END) AS customer_value_category,
    (SELECT COUNT(DISTINCT sr.returned_date_sk) 
     FROM store_returns sr
     WHERE sr.sr_customer_sk = cs.c_customer_sk) AS returns_count
FROM 
    Top_Sales ts
JOIN 
    Customer_Stats cs ON cs.website_count > 0
ORDER BY 
    ts.total_sales DESC, cs.avg_purchase_estimate DESC;
