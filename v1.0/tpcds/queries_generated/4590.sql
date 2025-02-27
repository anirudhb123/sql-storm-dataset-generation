
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
ReturnsSummary AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(r.loan_count, 0) AS returns,
    COALESCE(hv.total_net_paid, 0) AS customer_total,
    SUM(CASE 
            WHEN ws.ws_ext_sales_price IS NOT NULL THEN ws.ws_ext_sales_price 
            ELSE 0 
        END) AS total_sales,
    AVG(ws.ws_ext_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS number_of_orders,
    'Total Sales and Returns Summary' AS report_title
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
LEFT JOIN 
    ReturnsSummary r ON i.i_item_sk = r.sr_item_sk
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    HighValueCustomers hv ON hv.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (COALESCE(r.total_return_amt, 0) > 0 OR COALESCE(hv.total_net_paid, 0) > 0)
    AND i.i_current_price > 20 
GROUP BY 
    i.i_item_id, i.i_item_desc, r.loan_count, hv.total_net_paid
ORDER BY 
    number_of_orders DESC, total_sales DESC
LIMIT 100;
