
WITH RECURSIVE SalesTrend AS (
    SELECT 
        d.d_year AS SalesYear,
        SUM(ws.ext_sales_price) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ext_sales_price) DESC) AS Rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year
),
TopSales AS (
    SELECT 
        SalesYear, 
        TotalSales
    FROM 
        SalesTrend
    WHERE 
        Rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(ca.ca_state) AS State,
        COALESCE(SUM(ss.ss_net_profit), 0) AS TotalProfit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
FinalStats AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.State,
        TOP.TotalSales,
        ci.TotalProfit,
        CASE 
            WHEN ci.TotalProfit < 1000 THEN 'Low'
            WHEN ci.TotalProfit BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS ProfitCategory
    FROM 
        CustomerInfo ci
    CROSS JOIN 
        TopSales TOP
)
SELECT 
    fs.c_customer_id,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.State,
    fs.TotalSales,
    fs.TotalProfit,
    fs.ProfitCategory
FROM 
    FinalStats fs
WHERE 
    fs.TotalSales > (SELECT AVG(TotalSales) FROM FinalStats)
ORDER BY 
    fs.TotalProfit DESC
LIMIT 100;
