
WITH SalesSummary AS (
    SELECT 
        ws.sold_date_sk AS SalesDate,
        cs.cs_sold_date_sk AS CatalogSalesDate,
        COUNT(DISTINCT ws.ws_order_number) AS TotalWebSales,
        SUM(ws.ws_net_profit) AS TotalWebNetProfit,
        COUNT(DISTINCT cs.cs_order_number) AS TotalCatalogSales,
        SUM(cs.cs_net_profit) AS TotalCatalogNetProfit,
        d.d_year AS SaleYear,
        c.c_gender AS CustomerGender,
        c.cd_marital_status AS CustomerMaritalStatus
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        SalesDate, CatalogSalesDate, d.d_year, c.c_gender, c.cd_marital_status
),
AddressSummary AS (
    SELECT 
        ca.ca_state AS State,
        COUNT(DISTINCT c.c_customer_sk) AS UniqueCustomers,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_net_paid_inc_tax) AS TotalRevenue
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    ss.SaleYear,
    ss.CustomerGender,
    ss.CustomerMaritalStatus,
    SUM(ss.TotalWebSales) AS TotalWebSales,
    SUM(ss.TotalWebNetProfit) AS TotalWebNetProfit,
    SUM(asum.UniqueCustomers) AS TotalUniqueCustomers,
    SUM(asum.TotalOrders) AS TotalCatalogOrders,
    SUM(asum.TotalRevenue) AS TotalRevenue
FROM 
    SalesSummary ss
JOIN 
    AddressSummary asum ON ss.SaleYear = asum.State
GROUP BY 
    ss.SaleYear, ss.CustomerGender, ss.CustomerMaritalStatus
ORDER BY 
    ss.SaleYear, ss.CustomerGender, ss.CustomerMaritalStatus;
