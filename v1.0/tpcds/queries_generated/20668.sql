
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
), 
SalesData AS (
    SELECT 
        w.ws_sold_date_sk,
        w.ws_quantity,
        w.ws_net_profit,
        DATE_PART('year', d.d_date) AS sale_year,
        CASE WHEN w.ws_net_profit IS NULL THEN 'Unknown' ELSE 'Known' END AS profit_status
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2022
), 
SupplierDetails AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_item_sk
),
FilteredReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_returned_date_sk
    HAVING SUM(sr_return_amt) > 100
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    sd.sale_year,
    SUM(sd.ws_quantity) AS total_sales_quantity,
    SUM(sd.ws_net_profit) AS total_net_profit,
    CASE 
        WHEN fd.total_returns IS NOT NULL THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status,
    COALESCE(sd.total_net_profit, 0) - COALESCE(sd.total_sales_quantity * 0.1, 0) AS adjusted_profit,
    CASE 
        WHEN fd.total_return_amount IS NULL THEN 'No Returns'
        ELSE 'Returns Exist'
    END AS return_status_detail
FROM RankedCustomers rc
JOIN SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN FilteredReturns fd ON sd.ws_sold_date_sk = fd.sr_returned_date_sk
GROUP BY 
    rc.c_customer_id, 
    rc.cd_gender, 
    sd.sale_year, 
    fd.total_returns, 
    fd.total_return_amount
HAVING 
    total_net_profit > 0 OR SUM(sd.ws_quantity) > 5
ORDER BY 
    rc.cd_gender, 
    total_net_profit DESC;
