
WITH RankedReturns AS (
    SELECT 
        cr_item_sk, 
        cr_order_number, 
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY cr_item_sk ORDER BY SUM(cr_return_amount) DESC) as rank_order
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk, cr_order_number
), 
TopReturnedItems AS (
    SELECT 
        rr.cr_item_sk, 
        i.i_item_id, 
        rr.return_count, 
        rr.total_return_amount
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.cr_item_sk = i.i_item_sk
    WHERE 
        rr.rank_order <= 5
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
SalesData AS (
    SELECT 
        item.i_item_id, 
        SUM(ws.ws_quantity) AS total_sold_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales_value,
        ROW_NUMBER() OVER (PARTITION BY item.i_item_id ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws 
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(td.total_sales_value) AS total_sales_value,
    COUNT(DISTINCT tt.cr_order_number) AS total_returns,
    MAX(CASE WHEN tt.total_return_amount IS NOT NULL THEN tt.total_return_amount ELSE 0 END) AS max_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales_value
FROM 
    CustomerInfo ci
LEFT JOIN 
    TopReturnedItems tt ON ci.c_customer_sk = tt.cr_item_sk
LEFT JOIN 
    SalesData td ON tt.i_item_id = td.i_item_id AND td.sales_rank = 1
LEFT JOIN 
    store_sales ss ON ss.ss_item_sk = tt.cr_item_sk AND ss.ss_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = tt.cr_item_sk)
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status
HAVING 
    SUM(td.total_sales_value) > (SELECT COALESCE(AVG(ws_ext_sales_price), 0) FROM web_sales)
ORDER BY 
    total_sales_value DESC;
