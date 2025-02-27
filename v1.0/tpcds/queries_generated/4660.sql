
WITH total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(ib.ib_upper_bound, 0) AS income_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        SUM(ts.total_web_sales) AS total_sales,
        SUM(ts.total_net_profit) AS total_net_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        total_sales ts ON ci.c_customer_sk = ts.ws_item_sk
    GROUP BY 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_purchase_estimate, 
        ci.cd_credit_rating
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)

SELECT 
    rs.c_customer_sk,
    CONCAT(rs.c_first_name, ' ', rs.c_last_name) AS full_name,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.cd_purchase_estimate,
    rs.cd_credit_rating,
    rs.total_sales,
    rs.total_net_profit,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status,
    CASE 
        WHEN rs.income_lower_bound BETWEEN 0 AND 30000 THEN 'Low Income'
        WHEN rs.income_lower_bound BETWEEN 30001 AND 70000 THEN 'Middle Income'
        WHEN rs.income_lower_bound > 70000 THEN 'High Income'
        ELSE 'Unknown Income'
    END AS income_category
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 10  -- Get top 10 customers by sales
ORDER BY 
    rs.total_sales DESC;
