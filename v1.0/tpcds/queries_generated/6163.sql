
WITH SalesSummary AS (
    SELECT 
        d.d_year AS SalesYear,
        d.d_month_seq AS SalesMonth,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS TotalSales,
        SUM(ws.ws_ext_tax) AS TotalTax,
        COUNT(DISTINCT cs.cs_item_sk) AS UniqueItemsSold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
        AND cd.cd_gender = 'F'
        AND i.i_current_price BETWEEN 10.00 AND 100.00
    GROUP BY 
        d.d_year, d.d_month_seq
), TaxSummary AS (
    SELECT 
        SalesYear,
        SalesMonth,
        TotalTax,
        ROW_NUMBER() OVER (ORDER BY TotalTax DESC) AS Rank
    FROM 
        SalesSummary
), ItemSummary AS (
    SELECT 
        SalesYear,
        SalesMonth,
        SUM(UniqueItemsSold) AS TotalUniqueItems,
        AVG(TotalSales) AS AvgSalesPerItem
    FROM 
        SalesSummary
    GROUP BY 
        SalesYear, SalesMonth
)

SELECT 
    ts.SalesYear,
    ts.SalesMonth,
    ts.TotalTax,
    is.TotalUniqueItems,
    is.AvgSalesPerItem
FROM 
    TaxSummary ts
JOIN 
    ItemSummary is ON ts.SalesYear = is.SalesYear AND ts.SalesMonth = is.SalesMonth
WHERE 
    ts.Rank <= 5
ORDER BY 
    ts.TotalTax DESC, is.AvgSalesPerItem DESC;
