
WITH ranked_sales AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales s
    JOIN 
        item i ON s.ss_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND s.ss_net_paid > 0
    GROUP BY 
        s.ss_item_sk
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
), 
sales_data AS (
    SELECT 
        c.c_customer_sk,
        max(cs.total_net_profit) AS max_profit,
        MIN(COALESCE(ts.total_sales, 0)) AS min_total_sales,
        SUM(CASE WHEN d.d_current_year = 2023 THEN 1 ELSE 0 END) AS current_year_sales_count
    FROM 
        customer c
    LEFT JOIN 
        ranked_sales rs ON c.c_customer_sk = rs.ss_item_sk
    LEFT JOIN 
        (SELECT 
            ss_customer_sk, 
            SUM(ss_net_paid) AS total_sales 
         FROM 
            store_sales 
         GROUP BY 
            ss_customer_sk) ts ON c.c_customer_sk = ts.ss_customer_sk
    LEFT JOIN 
        date_dim d ON d.d_date_sk = ANY(ARRAY(SELECT ss_sold_date_sk FROM store_sales WHERE ss_customer_sk = c.c_customer_sk))
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_purchases,
    cs.avg_purchase_estimate,
    COALESCE(sd.max_profit, 0) AS max_profit,
    CASE WHEN cs.total_purchases > 10 THEN 'High Value Customer' ELSE 'Low Value Customer' END AS customer_value,
    sd.min_total_sales,
    sd.current_year_sales_count
FROM 
    customer_summary cs
LEFT JOIN 
    sales_data sd ON cs.c_customer_sk = sd.c_customer_sk
ORDER BY 
    cs.total_purchases DESC, 
    sd.max_profit DESC
FETCH FIRST 100 ROWS ONLY;
