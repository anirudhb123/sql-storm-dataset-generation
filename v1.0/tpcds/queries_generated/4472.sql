
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.sales_price,
        ws.list_price,
        CUS.c_first_name,
        CUS.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        D.d_year,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id, D.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer CUS ON ws.ws_bill_customer_sk = CUS.c_customer_sk
    JOIN 
        date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    GROUP BY 
        ws.web_site_id, 
        ws.sales_price, 
        ws.list_price, 
        CUS.c_first_name, 
        CUS.c_last_name, 
        D.d_year
),
TopSales AS (
    SELECT 
        CUS.c_first_name,
        CUS.c_last_name,
        SD.total_quantity,
        SD.total_sales_price,
        SD.d_year
    FROM 
        SalesData SD
    JOIN 
        customer CUS ON SD.web_site_id = CUS.c_current_addr_sk
    WHERE 
        SD.rank_sales <= 10
),
CustomerDemographics AS (
    SELECT 
        CD.cd_gender,
        CD.cd_marital_status,
        HD.hd_buy_potential
    FROM 
        customer_demographics CD
    LEFT JOIN 
        household_demographics HD ON CD.cd_demo_sk = HD.hd_demo_sk
)

SELECT 
    TS.c_first_name,
    TS.c_last_name,
    TS.total_quantity,
    TS.total_sales_price,
    CD.cd_gender,
    CD.cd_marital_status,
    CD.hd_buy_potential
FROM 
    TopSales TS
LEFT JOIN 
    CustomerDemographics CD ON TS.c_first_name = CD.cd_marital_status
WHERE 
    (TS.total_sales_price > 1000 OR TS.total_quantity > 50)
    AND CD.cd_gender IS NOT NULL
ORDER BY 
    TS.total_sales_price DESC;
