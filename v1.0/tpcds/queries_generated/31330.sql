
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item i
    JOIN (
        SELECT 
            ws_item_sk, 
            ws_quantity, 
            ws_sales_price, 
            ws_order_number 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    ) AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
income_band_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS demographic_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ci.c_customer_id,
    ss.total_sales,
    ss.order_count,
    i.total_quantity_sold,
    i.avg_sales_price,
    ibs.demographic_count
FROM 
    sales_summary ss
JOIN 
    customer_info ci ON ss.customer_id = ci.c_customer_id
LEFT JOIN 
    item_summary i ON ss.customer_id IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = i.i_item_sk)
LEFT JOIN 
    income_band_summary ibs ON ci.cd_income_band_sk = ibs.ib_income_band_sk
WHERE 
    (ci.cd_marital_status = 'M' OR ci.cd_gender = 'F') 
    AND ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
