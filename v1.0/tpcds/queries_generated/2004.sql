
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_current_cdemo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value_segment
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ItemSales AS (
    SELECT 
        sd.ws_item_sk,
        AVG(sd.total_net_profit) AS avg_net_profit,
        DENSE_RANK() OVER (ORDER BY AVG(sd.total_net_profit) DESC) AS sales_rank
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.customer_value_segment,
    is.ws_item_sk,
    is.avg_net_profit,
    CASE
        WHEN is.sales_rank <= 10 THEN 'Top Selling Item'
        ELSE 'Not Top Selling Item'
    END AS item_status
FROM 
    CustomerStats cs
LEFT JOIN 
    ItemSales is ON cs.c_current_cdemo_sk = is.ws_item_sk
WHERE 
    cs.cd_gender IS NOT NULL
    AND cs.customer_value_segment <> 'Low Value'
ORDER BY 
    cs.c_customer_sk, is.avg_net_profit DESC;
