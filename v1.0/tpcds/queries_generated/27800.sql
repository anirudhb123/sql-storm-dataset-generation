
WITH AddressDetails AS (
    SELECT 
        ca.city AS AddressCity,
        ca.state AS AddressState,
        COUNT(DISTINCT c.c_customer_id) AS CustomerCount
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.state
),
IncomeBandDetails AS (
    SELECT 
        cd.cd_gender AS Gender,
        ib.ib_lower_bound AS IncomeLowerBound,
        ib.ib_upper_bound AS IncomeUpperBound,
        COUNT(DISTINCT c.c_customer_id) AS CustomerCountInBand
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
),
SalesDetails AS (
    SELECT 
        ws.web_sold_date_sk AS SalesDate,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_sold_date_sk
),
FinalMetrics AS (
    SELECT 
        ad.AddressCity,
        ad.AddressState,
        ib.Gender,
        ib.IncomeLowerBound,
        ib.IncomeUpperBound,
        ib.CustomerCountInBand,
        sd.SalesDate,
        sd.TotalSales,
        sd.TotalOrders
    FROM 
        AddressDetails ad
    JOIN 
        IncomeBandDetails ib ON ad.CustomerCount > 0
    JOIN 
        SalesDetails sd ON sd.TotalOrders > 0
)
SELECT 
    AddressCity,
    AddressState,
    Gender,
    IncomeLowerBound,
    IncomeUpperBound,
    CustomerCountInBand,
    SalesDate,
    TotalSales,
    TotalOrders
FROM 
    FinalMetrics
ORDER BY 
    AddressCity, AddressState, IncomeLowerBound;
