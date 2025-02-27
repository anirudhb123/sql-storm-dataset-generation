
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateSales AS (
    SELECT 
        sd.d_year,
        sd.d_month_seq,
        sd.d_week_seq,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
    FROM 
        SalesData sd
    GROUP BY 
        sd.d_year, sd.d_month_seq, sd.d_week_seq
),
SalesRanked AS (
    SELECT 
        asd.*,
        RANK() OVER (PARTITION BY asd.d_year ORDER BY asd.total_sales DESC) AS sales_rank
    FROM 
        AggregateSales asd
)
SELECT 
    c.c_customer_sk,
    c.c_birth_year,
    c.cd_gender,
    c.cd_marital_status,
    sr.d_year,
    sr.total_sales,
    sr.sales_rank
FROM 
    CustomerData c
LEFT JOIN 
    SalesRanked sr ON c.cd_income_band_sk IS NOT NULL
WHERE 
    (c.c_birth_year IS NOT NULL AND c.c_birth_year < 1980)
    OR (c.cd_gender = 'F' AND c.cd_marital_status = 'W')
    AND sr.sales_rank <= 5
ORDER BY 
    sr.d_year, sr.total_sales DESC;
