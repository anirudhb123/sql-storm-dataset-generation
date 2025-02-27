
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= 2450000 -- arbitrary date range start
        AND i.i_current_price > 20
),
FilteredSales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_order_number
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
MaritalIncomeStats AS (
    SELECT 
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        COUNT(c.c_customer_id) AS customer_count,
        AVG(fs.total_sales) AS avg_sales,
        AVG(fs.total_profit) AS avg_profit
    FROM 
        FilteredSales fs
    JOIN 
        CustomerDetails cd ON fs.ws_order_number = cd.c_customer_id
    LEFT JOIN 
        household_demographics hd ON cd.cd_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_marital_status, ib.ib_income_band_sk
)
SELECT 
    mis.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(mis.customer_count, 0) AS customer_count,
    COALESCE(mis.avg_sales, 0) AS avg_sales,
    COALESCE(mis.avg_profit, 0) AS avg_profit
FROM 
    income_band ib
LEFT JOIN 
    MaritalIncomeStats mis ON ib.ib_income_band_sk = mis.ib_income_band_sk
ORDER BY 
    ib.ib_lower_bound;
