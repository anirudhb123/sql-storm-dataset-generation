
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_ticket_number = ws.ws_order_number
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2458123 AND 2458128 -- Example date range
    GROUP BY 
        s.s_store_id, c.c_customer_id
),
demographic_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        COUNT(DISTINCT sss.c_customer_id) AS customer_count,
        SUM(ss.total_sales) AS total_sales,
        SUM(ss.total_quantity) AS total_quantity,
        AVG(ss.avg_net_profit) AS avg_net_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    JOIN 
        customer_address ca ON ss.c_customer_id = ca.ca_address_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, ca.ca_state
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_id) AS count_customers,
        SUM(s.total_sales) AS total_sales
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        sales_summary s ON c.c_customer_id = s.c_customer_id
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.ca_state,
    COUNT(DISTINCT da.customer_count) AS demographic_count,
    SUM(da.total_sales) AS overall_sales,
    SUM(da.total_quantity) AS overall_quantity,
    AVG(da.avg_net_profit) AS overall_avg_profit,
    id.count_customers AS income_count,
    id.total_sales AS income_sales
FROM 
    demographic_analysis da
JOIN 
    income_distribution id ON da.customer_count = id.count_customers
GROUP BY 
    da.cd_gender, da.cd_marital_status, da.ca_state, id.count_customers, id.total_sales
ORDER BY 
    overall_sales DESC;
