
WITH customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer 
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    JOIN 
        store ON web_sales.ws_store_sk = store.s_store_sk
    GROUP BY 
        s_store_sk
),
returns_summary AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    ss.total_sales,
    ss.total_quantity,
    ss.avg_sales_price,
    rs.total_returns,
    rs.total_return_amount
FROM 
    customer_stats cs
JOIN 
    sales_summary ss ON cs.customer_count > 100
JOIN 
    returns_summary rs ON ss.s_store_sk = rs.sr_store_sk
ORDER BY 
    cs.customer_count DESC, ss.total_sales DESC;
