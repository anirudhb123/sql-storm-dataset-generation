
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY (ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2021)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_income_band_sk,
        ib.ib_lower_bound, 
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
TopSales AS (
    SELECT 
        sd.ws_item_sk, 
        SUM(sd.total_sales) AS total_sales_amount
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    ci.cd_gender,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    COALESCE(ts.total_sales_amount, 0) AS total_sales_amount,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    TopSales ts ON ci.cd_income_band_sk = ts.ws_item_sk
GROUP BY 
    ci.cd_gender, ci.ib_lower_bound, ci.ib_upper_bound
HAVING 
    COUNT(DISTINCT ci.c_customer_sk) > 5
ORDER BY 
    total_sales_amount DESC;
