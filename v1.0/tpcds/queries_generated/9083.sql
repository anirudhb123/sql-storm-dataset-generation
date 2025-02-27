
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id, c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(rs.total_sales) AS aggregate_sales
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(cd.aggregate_sales) AS total_aggregate_sales
FROM 
    CustomerDemographics cd
JOIN 
    income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    total_aggregate_sales DESC;
