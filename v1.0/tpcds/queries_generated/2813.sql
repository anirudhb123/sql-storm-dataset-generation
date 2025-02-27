
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        CustomerSummary cs ON ws.ws_customer_sk = cs.c_customer_sk
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
FinalSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        sd.total_sales,
        sd.avg_net_profit,
        rd.total_returns,
        rd.avg_return_amount,
        CASE 
            WHEN sd.total_sales IS NULL THEN 'No Sales'
            ELSE 'Sales Recorded'
        END AS sales_status
    FROM 
        CustomerSummary cs
    LEFT JOIN 
        SalesData sd ON cs.c_customer_sk = sd.ws_customer_sk
    LEFT JOIN 
        ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE 
        cs.rnk = 1
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    COALESCE(f.total_sales, 0) AS total_sales,
    COALESCE(f.avg_net_profit, 0) AS avg_net_profit,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.avg_return_amount, 0) AS avg_return_amount,
    f.sales_status
FROM 
    FinalSummary f
WHERE 
    f.total_sales > 1000 OR f.avg_net_profit > 100
ORDER BY 
    f.total_sales DESC, f.avg_net_profit DESC;
