
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS average_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT wd.web_page_sk) AS total_web_visits,
        COUNT(DISTINCT sr.return_ticket_number) AS total_returns
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_page wd ON wd.wp_customer_sk = c.c_customer_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000  -- Example date range
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_education_status, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    s.*,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    sales_summary s
ORDER BY 
    total_sales DESC
LIMIT 100;
