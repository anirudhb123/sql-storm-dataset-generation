
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ci.c_item_sk,
        ci.i_item_desc,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        item AS ci ON ss.ss_item_sk = ci.i_item_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 1000 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, 
        hd.hd_income_band_sk, hd.hd_buy_potential, ci.c_item_sk, ci.i_item_desc
),
SalesData AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_quantity,
        cd.total_sales_amount,
        sd.warehouse_id,
        sd.order_count,
        sd.total_net_profit
    FROM 
        CustomerData AS cd
    LEFT JOIN 
        SalesData AS sd ON cd.c_item_sk = sd.warehouse_id
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_quantity,
    fr.total_sales_amount,
    COALESCE(fr.order_count, 0) AS order_count,
    COALESCE(fr.total_net_profit, 0.00) AS total_net_profit
FROM 
    FinalReport AS fr
ORDER BY 
    fr.total_sales_amount DESC
LIMIT 100;
