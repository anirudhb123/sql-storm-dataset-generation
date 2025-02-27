
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        d.d_year, c.c_gender
),
SalesRanked AS (
    SELECT 
        d_year,
        c_gender,
        total_sales,
        total_orders,
        avg_net_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
),
TopSales AS (
    SELECT 
        d_year,
        c_gender,
        total_sales,
        total_orders,
        avg_net_profit
    FROM 
        SalesRanked
    WHERE 
        sales_rank <= 3
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM 
        customer_demographics
    WHERE 
        cd_marital_status = 'M' OR cd_marital_status IS NULL
),
IncomeGroup AS (
    SELECT 
        ib_income_band_sk,
        CASE 
            WHEN ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL 
            THEN CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
            ELSE 'Unknown'
        END AS income_range
    FROM 
        income_band
),
FinalReport AS (
    SELECT 
        ts.d_year,
        ts.c_gender,
        ts.total_sales,
        ts.total_orders,
        ts.avg_net_profit,
        cd.cd_marital_status,
        ig.income_range
    FROM 
        TopSales AS ts
    LEFT JOIN 
        CustomerDemographics AS cd ON ts.c_gender = cd.cd_gender
    LEFT JOIN 
        IncomeGroup AS ig ON cd.cd_income_band_sk = ig.ib_income_band_sk
)
SELECT 
    d_year,
    c_gender,
    SUM(total_sales) AS grand_total_sales,
    SUM(total_orders) AS grand_total_orders,
    AVG(avg_net_profit) AS avg_grand_net_profit
FROM 
    FinalReport
GROUP BY 
    d_year, c_gender
ORDER BY 
    d_year, c_gender;
