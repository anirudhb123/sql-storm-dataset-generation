
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        d.d_year = 2022 AND w.web_state = 'NY'
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(rs.total_sales) AS aggregated_sales
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.web_site_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
TopDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        aggregated_sales,
        RANK() OVER (ORDER BY aggregated_sales DESC) AS rank
    FROM 
        CustomerDemographics cd
)
SELECT 
    td.cd_gender,
    td.cd_marital_status,
    td.aggregated_sales
FROM 
    TopDemographics td
WHERE 
    td.rank <= 5
ORDER BY 
    td.aggregated_sales DESC;
