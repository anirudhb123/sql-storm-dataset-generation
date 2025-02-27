
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
ReturnsStats AS (
    SELECT 
        wr.wr_web_page_sk,
        COUNT(*) AS TotalReturns,
        SUM(wr.wr_return_amt) AS TotalReturnAmount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_web_page_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS CustomerCount,
        AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimate,
        SUM(COALESCE(cd.cd_dep_count, 0)) AS TotalDependents
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    r.web_site_id,
    r.TotalSales,
    r.SalesRank,
    COALESCE(rs.TotalReturns, 0) AS TotalReturns,
    COALESCE(rs.TotalReturnAmount, 0) AS TotalReturnAmount,
    cd.cd_gender,
    cd.CustomerCount,
    cd.AvgPurchaseEstimate,
    cd.TotalDependents
FROM 
    RankedSales r
LEFT JOIN 
    ReturnsStats rs ON r.ws_order_number = rs.wr_web_page_sk
LEFT JOIN 
    CustomerDemographics cd ON r.SalesRank <= 10
WHERE 
    r.TotalSales > (SELECT AVG(TotalSales) FROM RankedSales)
AND 
    (r.TotalSales IS NOT NULL OR rs.TotalReturns IS NOT NULL)
ORDER BY 
    r.TotalSales DESC, cd.CustomerCount DESC;
