
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer_demographics
),
SaleData AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        DENSE_RANK() OVER (ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL AND 
        ws_quantity > 0
),
ChurnedCustomers AS (
    SELECT 
        c.c_customer_id,
        DATEDIFF(CURRENT_DATE, MAX(ws.ws_sold_date_sk)) AS days_since_last_purchase
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        days_since_last_purchase > 365
)
SELECT 
    w.w_warehouse_name,
    i.i_item_id,
    COALESCE(SUM(CASE WHEN sr.return_count IS NOT NULL THEN sr.return_count ELSE 0 END), 0) AS total_returns,
    AVG(sd.ws_net_profit) AS average_profit,
    cd.purchase_category,
    COUNT(DISTINCT cc.c_customer_id) AS churned_customer_count
FROM 
    warehouse w
LEFT JOIN 
    inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN 
    item i ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN 
    RankedReturns sr ON i.i_item_sk = sr.sr_item_sk AND sr.rnk = 1
JOIN 
    SaleData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerDemographics cd ON sd.ws_item_sk = cd.cd_demo_sk
LEFT JOIN 
    ChurnedCustomers cc ON cc.c_customer_id = sd.ws_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2) 
    AND w.w_warehouse_name IS NOT NULL
    AND cd_gender IS NOT NULL
GROUP BY 
    w.w_warehouse_name, i.i_item_id, cd.purchase_category
HAVING 
    COUNT(DISTINCT cc.c_customer_id) > 10
ORDER BY 
    total_returns DESC, average_profit DESC
LIMIT 10;
