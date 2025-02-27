
WITH Total_Sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_paid_inc_tax) AS total_sales,
        COUNT(cs_order_number) AS number_of_sales
    FROM
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2459018 AND 2459325
    GROUP BY 
        cs_item_sk
),
Top_Items AS (
    SELECT 
        ts.cs_item_sk,
        ts.total_sales,
        ts.number_of_sales,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        Total_Sales ts
    WHERE 
        ts.total_sales IS NOT NULL
    AND ts.number_of_sales > 10
),
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Sales_Analysis AS (
    SELECT 
        ti.cs_item_sk,
        t.total_sales,
        t.number_of_sales,
        cd.cd_gender,
        CASE 
            WHEN cd.ib_lower_bound IS NULL THEN 'Unknown'
            WHEN cd.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT(cd.ib_lower_bound, '-', cd.ib_upper_bound)
        END AS income_band
    FROM 
        Top_Items ti
    JOIN 
        store_sales ss ON ti.cs_item_sk = ss.ss_item_sk
    LEFT JOIN 
        Customer_Demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    sa.cs_item_sk,
    sa.total_sales,
    sa.number_of_sales,
    sa.cd_gender,
    sa.income_band,
    RANK() OVER (PARTITION BY sa.income_band ORDER BY sa.total_sales DESC) AS income_band_rank
FROM 
    Sales_Analysis sa
WHERE 
    sa.cd_gender IN ('M', 'F')
ORDER BY 
    sa.income_band, sa.total_sales DESC;

WITH Web_Returns_Summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amount) AS total_return_amount,
        COUNT(wr_return_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
Combined_Sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_net_profit AS net_profit,
        COALESCE(wrs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN ws.ws_net_profit - COALESCE(wrs.total_return_amount, 0) > 0 THEN 'Profitable'
            ELSE 'Unprofitable'
        END AS profitability_status
    FROM 
        web_sales ws
    LEFT JOIN 
        Web_Returns_Summary wrs ON ws.ws_item_sk = wrs.wr_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459018 AND 2459325
)
SELECT 
    cs.cs_item_sk,
    cs.net_profit,
    cs.total_return_amount,
    cs.profitability_status
FROM 
    Combined_Sales cs
ORDER BY 
    cs.net_profit DESC
LIMIT 10;
