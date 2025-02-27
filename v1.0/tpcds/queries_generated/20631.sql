
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(ss.ss_quantity, 0) AS store_qty,
        COALESCE(ws.ws_quantity, 0) AS web_qty,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_list_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        OR ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregateSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.store_qty) AS total_store_qty,
        SUM(sd.web_qty) AS total_web_qty,
        SUM(sd.ws_net_profit) AS total_net_profit,
        SUM(sd.ws_ext_discount_amt) AS total_discount
    FROM 
        SalesData sd
    WHERE 
        sd.rnk = 1
    GROUP BY 
        sd.ws_item_sk
),
PriceCalculation AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(as.total_store_qty, 0) AS total_store_qty,
        COALESCE(as.total_web_qty, 0) AS total_web_qty,
        COALESCE(as.total_net_profit, 0) AS total_net_profit,
        COALESCE(as.total_discount, 0) AS total_discount,
        CASE 
            WHEN COALESCE(as.total_store_qty, 0) + COALESCE(as.total_web_qty, 0) > 0 THEN 
                ROUND((COALESCE(as.total_net_profit, 0) / (COALESCE(as.total_store_qty, 0) + COALESCE(as.total_web_qty, 0))), 2)
            ELSE 
                NULL 
        END AS avg_profit_per_item
    FROM 
        item i
    LEFT JOIN 
        AggregateSales as ON i.i_item_sk = as.ws_item_sk
)
SELECT 
    pc.i_item_id,
    pc.i_item_desc,
    pc.total_store_qty,
    pc.total_web_qty,
    CASE 
        WHEN pc.total_discount > 0 THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS discount_status,
    pc.avg_profit_per_item,
    CASE 
        WHEN pc.avg_profit_per_item IS NULL THEN 'No Sales Yet'
        WHEN pc.avg_profit_per_item < 1 THEN 'Low Profit'
        ELSE 'Satisfactory Profit'
    END AS profit_status
FROM 
    PriceCalculation pc
WHERE 
    PC.total_store_qty + PC.total_web_qty >= 5
ORDER BY 
    pc.avg_profit_per_item DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
