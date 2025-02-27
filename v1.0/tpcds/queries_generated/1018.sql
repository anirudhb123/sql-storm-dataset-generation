
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ship_date_sk,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk, wr.wr_order_number
),
AggregatedSales AS (
    SELECT 
        sd.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(sd.ws_net_paid) AS total_net_paid,
        MAX(sd.d_date) AS last_sale_date
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk AND sd.ws_order_number = rd.wr_order_number
    WHERE 
        rd.total_return_qty IS NULL OR rd.total_return_qty = 0
    GROUP BY 
        sd.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    a.ws_item_sk,
    COALESCE(ad.total_sales, 0) AS total_sales,
    COALESCE(ad.total_net_paid, 0) AS total_net_paid,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    AggregatedSales ad
JOIN 
    item i ON ad.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.c_customer_sk IN (
        SELECT DISTINCT 
            ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = ad.ws_item_sk
    )
WHERE 
    i.i_current_price < 100.00 
    AND i.i_rec_start_date <= CURRENT_DATE 
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE)
GROUP BY 
    a.ws_item_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_net_paid DESC 
LIMIT 10;
