
WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 0
), demographic_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS demographics_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), income_band_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(hd.hd_buy_potential) AS total_buy_potential,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
), order_refunds AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), combined_summary AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        COALESCE(co.total_orders, 0) AS order_count,
        COALESCE(co.total_spent, 0) AS order_value,
        ds.demographics_count,
        ds.average_purchase_estimate,
        ibs.total_buy_potential,
        ibs.customer_count,
        os.total_returns,
        os.total_return_amount
    FROM 
        customer_orders co
    FULL OUTER JOIN 
        demographic_summary ds ON ds.demographics_count > 10 -- arbitrary condition for demonstration
    FULL OUTER JOIN 
        income_band_summary ibs ON ibs.customer_count > 5
    FULL OUTER JOIN 
        order_refunds os ON os.sr_item_sk = co.c_customer_sk
)
SELECT 
    CBS.c_customer_sk,
    CBS.c_first_name,
    CBS.c_last_name,
    CBS.order_count,
    CBS.order_value,
    CBS.demographics_count,
    CBS.average_purchase_estimate,
    CBS.total_buy_potential,
    CBS.customer_count,
    CBS.total_returns,
    CBS.total_return_amount,
    CASE 
        WHEN CBS.order_value > (SELECT AVG(order_value) FROM combined_summary) THEN 'Above Average'
        WHEN CBS.order_value < (SELECT AVG(order_value) FROM combined_summary) THEN 'Below Average'
        ELSE 'Average'
    END AS spending_category
FROM 
    combined_summary CBS
WHERE 
    CBS.order_count > 5 
ORDER BY 
    CBS.order_value DESC
LIMIT 100;
