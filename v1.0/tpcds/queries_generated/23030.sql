
WITH RECURSIVE CustomerGroups AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_customer_sk) AS grp
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S')
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq IN (10, 11) AND d_dow NOT IN (0, 6))
    GROUP BY 
        ws.ws_item_sk
),
ReturnRates AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS returner_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    cg.c_first_name,
    cg.c_last_name,
    cg.cd_gender,
    sd.item_desc,
    sd.total_quantity,
    sd.total_net_profit,
    rr.total_returns,
    rr.total_return_amount,
    CASE 
        WHEN rr.total_returns IS NULL THEN 'No Returns'
        WHEN rr.returner_count > 5 THEN 'High Return Rate'
        ELSE 'Normal'
    END AS return_status,
    (SELECT COUNT(*) FROM SalesData WHERE profit_rank <= 10) AS top_sales_count,
    (SELECT COUNT(DISTINCT sr_cdemo_sk) FROM store_returns WHERE sr_return_quantity > 0) AS unique_customers_returned
FROM 
    CustomerGroups cg
JOIN 
    SalesData sd ON sd.ws_item_sk = (SELECT i_item_sk FROM item WHERE i_item_desc LIKE '%' || cg.c_first_name || '%')
LEFT JOIN 
    ReturnRates rr ON rr.cr_item_sk = sd.ws_item_sk
WHERE 
    COALESCE(rr.total_return_amount, 0) < sd.total_net_profit
ORDER BY 
    sd.total_net_profit DESC, cg.c_last_name ASC
LIMIT 50 OFFSET 0;
