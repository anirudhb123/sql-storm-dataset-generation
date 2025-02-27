
WITH RECURSIVE SeasonalSales AS (
    SELECT 
        ds.d_year,
        SUM(CASE WHEN ds.d_moy IN (12, 1, 2) THEN ss.ss_net_profit ELSE 0 END) AS WinterSales,
        SUM(CASE WHEN ds.d_moy IN (3, 4, 5) THEN ss.ss_net_profit ELSE 0 END) AS SpringSales,
        SUM(CASE WHEN ds.d_moy IN (6, 7, 8) THEN ss.ss_net_profit ELSE 0 END) AS SummerSales,
        SUM(CASE WHEN ds.d_moy IN (9, 10, 11) THEN ss.ss_net_profit ELSE 0 END) AS AutumnSales
    FROM 
        store_sales ss
    JOIN 
        date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    GROUP BY 
        ds.d_year
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS ReturnCount,
        SUM(COALESCE(sr_return_amt, 0)) AS TotalReturnAmt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(c.CustomerCount), 0) AS CustomerCount
    FROM 
        customer_demographics cd
    LEFT JOIN (
        SELECT 
            c.c_customer_sk,
            COUNT(DISTINCT c.c_customer_id) AS CustomerCount
        FROM 
            customer c 
        GROUP BY 
            c.c_customer_sk
    ) c ON cd.cd_demo_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.d_year,
    cs.WinterSales,
    cs.SpringSales,
    cs.SummerSales,
    cs.AutumnSales,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(COALESCE(cr.ReturnCount, 0)) AS TotalReturns,
    SUM(COALESCE(cr.TotalReturnAmt, 0)) AS TotalReturnAmt,
    RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.WinterSales DESC) AS WinterRank,
    RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.SpringSales DESC) AS SpringRank,
    RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.SummerSales DESC) AS SummerRank,
    RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.AutumnSales DESC) AS AutumnRank
FROM 
    SeasonalSales cs
LEFT JOIN 
    CustomerReturns cr ON cr.sr_returning_customer_sk IS NOT NULL
JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk IS NOT NULL
GROUP BY 
    cs.d_year, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(cs.WinterSales + cs.SpringSales + cs.SummerSales + cs.AutumnSales) > 0
ORDER BY 
    cs.d_year, cs.WinterSales DESC;
