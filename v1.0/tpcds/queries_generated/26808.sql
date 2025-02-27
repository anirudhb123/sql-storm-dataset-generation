
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
SalesPromotion AS (
    SELECT 
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_name
),
DailySales AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.ws_net_sales) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
RankedSales AS (
    SELECT 
        sale_date,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        DailySales
)
SELECT 
    ac.ca_state,
    ac.address_count,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status,
    dm.demographic_count,
    sp.p_promo_name,
    sp.total_profit,
    rs.sale_date,
    rs.total_sales,
    rs.sales_rank
FROM 
    AddressCounts ac
JOIN 
    Demographics dm ON TRUE  -- CROSS JOIN to combine every address with every demographic
JOIN 
    SalesPromotion sp ON TRUE  -- CROSS JOIN to distribute every promo to every demographic-address combination
JOIN 
    RankedSales rs ON rs.sales_rank <= 10;  -- Joining only top 10 ranked sales
