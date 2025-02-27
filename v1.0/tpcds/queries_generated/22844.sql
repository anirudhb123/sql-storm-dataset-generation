
WITH RECURSIVE demographic_summary AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_demo_sk ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE cd.cd_gender IN ('M', 'F') AND (hd.hd_dep_count IS NULL OR hd.hd_dep_count > 0)
),
sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
returns_data AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
combined_sales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        COALESCE(rd.total_net_loss, 0) AS total_net_loss,
        (CASE 
            WHEN COALESCE(rd.total_return_quantity, 0) = 0 THEN 1 
            ELSE sd.total_quantity / NULLIF(rd.total_return_quantity, 0) 
         END) AS return_ratio
    FROM sales_data sd
    LEFT JOIN returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
),
final_analysis AS (
    SELECT
        cs.ca_state,
        cs.ca_city,
        SUM(cs.ss_net_profit) AS total_profit,
        COUNT(DISTINCT cs.ss_ticket_number) AS total_sales,
        AVG(cs.ss_sales_price) AS avg_sales_price,
        MAX(cs.ss_sold_date_sk) AS most_recent_sale,
        COUNT(DISTINCT ds.cd_demo_sk) AS customer_count,
        MAX(ds.buy_potential) AS best_buy_potential
    FROM store_sales cs
    JOIN combined_sales csa ON cs.ss_item_sk = csa.ws_item_sk
    JOIN demographic_summary ds ON ds.cd_demo_sk IN (
        SELECT c.c_current_cdemo_sk 
        FROM customer c WHERE c.c_current_addr_sk = cs.ss_store_sk 
    )
    WHERE (csa.total_net_paid - csa.total_return_amt) > 0
    GROUP BY cs.ca_address_sk, cs.ca_city, cs.ca_state
    HAVING SUM(cs.ss_net_profit) > 1000 AND AVG(cs.ss_sales_price) < (SELECT AVG(ss_sales_price) FROM store_sales)
)
SELECT 
    fa.ca_state,
    fa.ca_city,
    fa.total_profit,
    fa.total_sales,
    fa.avg_sales_price,
    fa.most_recent_sale,
    fa.customer_count,
    fa.best_buy_potential
FROM final_analysis fa
WHERE fa.customer_count > 10 AND fa.best_buy_potential IS NOT NULL
ORDER BY fa.total_profit DESC, fa.avg_sales_price ASC
LIMIT 100;
