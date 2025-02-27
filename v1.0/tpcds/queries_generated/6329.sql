
WITH RecentSales AS (
    SELECT 
        ws.web_site_id,
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3) -- First quarter of 2023
    GROUP BY 
        ws.web_site_id, c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesAnalysis AS (
    SELECT 
        rs.web_site_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(rs.total_quantity) AS total_quantity,
        SUM(rs.total_sales) AS total_sales,
        COUNT(DISTINCT rs.total_orders) AS distinct_orders
    FROM 
        RecentSales rs
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = rs.c_customer_id
    GROUP BY 
        rs.web_site_id, cd.cd_gender, cd.cd_marital_status
),
RankedSales AS (
    SELECT 
        web_site_id,
        cd_gender,
        cd_marital_status,
        total_quantity,
        total_sales,
        distinct_orders,
        RANK() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesAnalysis
)
SELECT 
    web_site_id,
    cd_gender,
    cd_marital_status,
    total_quantity,
    total_sales,
    distinct_orders,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 5 -- Top 5 sales demographics by site
ORDER BY 
    web_site_id, sales_rank;
