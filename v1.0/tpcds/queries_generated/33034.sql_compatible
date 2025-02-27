
WITH RECURSIVE CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cte.level + 1
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerCTE cte ON cd.cd_purchase_estimate < cte.cd_purchase_estimate
    WHERE 
        cte.level < 3
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        CustomerCTE cte ON ws.ws_bill_customer_sk = cte.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_profit,
        sd.rank,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
    WHERE 
        sd.rank = 1
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    COALESCE(rs.total_sales, 0) AS sales,
    COALESCE(rs.total_profit, 0) AS profit,
    CASE 
        WHEN rs.profit_rank IS NULL THEN 'No sales'
        ELSE 'Top Performer'
    END AS performance
FROM 
    item it
LEFT JOIN 
    RankedSales rs ON it.i_item_sk = rs.ws_item_sk
WHERE 
    (it.i_brand_id IN (SELECT DISTINCT i_brand_id FROM item WHERE i_current_price > 10) 
     OR it.i_category_id IN (SELECT DISTINCT i_category_id FROM item WHERE i_color LIKE '%Red%'))
ORDER BY 
    profit DESC, sales DESC
LIMIT 100;
