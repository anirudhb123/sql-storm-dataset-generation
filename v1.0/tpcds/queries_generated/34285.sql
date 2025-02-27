
WITH RECURSIVE SalesCTE AS (
    SELECT 
        cs_bill_customer_sk,
        cs_quantity,
        cs_net_paid,
        cs_sold_date_sk,
        1 AS Level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        cs.bill_customer_sk,
        SUM(cs.cs_quantity) OVER (PARTITION BY cs_bill_customer_sk ORDER BY cs_sold_date_sk) AS cs_quantity,
        SUM(cs.cs_net_paid) OVER (PARTITION BY cs_bill_customer_sk ORDER BY cs_sold_date_sk) AS cs_net_paid,
        cs.cs_sold_date_sk,
        Level + 1
    FROM 
        catalog_sales cs
    JOIN 
        SalesCTE s ON s.cs_bill_customer_sk = cs_bill_customer_sk
    WHERE 
        s.Level < 10
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    MAX(sc.cs_quantity) AS Total_Quantity,
    MAX(sc.cs_net_paid) AS Total_Net_Paid,
    CASE 
        WHEN MAX(sc.cs_net_paid) IS NULL THEN 'No Sales'
        WHEN MAX(sc.cs_net_paid) < 1000 THEN 'Low Sales'
        ELSE 'High Sales' 
    END AS Sales_Category
FROM 
    SalesCTE sc
LEFT JOIN 
    customer c ON sc.cs_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_purpose IS NOT NULL
GROUP BY 
    c.c_first_name, c.c_last_name
HAVING 
    MAX(sc.cs_net_paid) IS NOT NULL
ORDER BY 
    Total_Net_Paid DESC
LIMIT 50;
