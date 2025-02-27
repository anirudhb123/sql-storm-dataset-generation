
WITH CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk AS customer_sk, 
        SUM(wr.return_quantity) AS total_return_quantity, 
        SUM(wr.return_amt) AS total_return_amt, 
        SUM(wr.return_ship_cost) AS total_return_ship_cost
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
),
SalesSummary AS (
    SELECT 
        ws.bill_customer_sk AS customer_sk, 
        COUNT(ws.order_number) AS total_orders, 
        SUM(ws.ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
DemographicSummary AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(cs.net_profit) AS total_profit
    FROM 
        catalog_sales cs
    JOIN 
        customer c ON cs.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
ComprehensiveAnalysis AS (
    SELECT 
        cs.customer_sk,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.total_return_ship_cost, 0) AS total_return_ship_cost
    FROM 
        (SELECT DISTINCT customer_sk FROM CustomerReturns UNION SELECT DISTINCT customer_sk FROM SalesSummary) cs
    LEFT JOIN 
        SalesSummary ss ON cs.customer_sk = ss.customer_sk
    LEFT JOIN 
        CustomerReturns cr ON cs.customer_sk = cr.customer_sk
)
SELECT 
    ca.city,
    ca.state,
    da.cd_gender,
    da.cd_marital_status,
    SUM(ca.total_sales) AS total_sales_by_location,
    SUM(ca.total_return_amt) AS total_return_amt_by_location,
    COUNT(DISTINCT ca.customer_sk) AS unique_customers
FROM 
    ComprehensiveAnalysis ca
JOIN 
    customer c ON ca.customer_sk = c.c_customer_sk
JOIN 
    customer_demographics da ON c.c_current_cdemo_sk = da.cd_demo_sk
JOIN 
    customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
GROUP BY 
    ca.city, ca.state, da.cd_gender, da.cd_marital_status
HAVING 
    SUM(ca.total_sales) > 10000
ORDER BY 
    total_sales_by_location DESC, unique_customers DESC;
