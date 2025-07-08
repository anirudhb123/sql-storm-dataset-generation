
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopReturningItems AS (
    SELECT 
        rt.sr_item_sk,
        rt.return_count,
        rt.total_return_amount,
        i.i_item_desc,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        RankedReturns rt
    JOIN
        item i ON rt.sr_item_sk = i.i_item_sk
    LEFT OUTER JOIN 
        customer c ON c.c_customer_sk = (
            SELECT 
                sr_customer_sk 
            FROM 
                store_returns 
            WHERE 
                sr_item_sk = rt.sr_item_sk 
            ORDER BY 
                sr_returned_date_sk DESC 
            LIMIT 1
        )
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        rt.return_rank <= 10
)
SELECT 
    t1.sr_item_sk,
    COALESCE(t1.return_count, 0) AS return_count,
    COALESCE(t1.total_return_amount, 0) AS total_return_amount,
    t1.i_item_desc,
    t1.i_current_price,
    w.w_warehouse_name,
    SUM(ws.ws_net_profit) OVER (PARTITION BY t1.sr_item_sk) AS total_profit,
    CASE 
        WHEN t1.return_count > 100 THEN 'High Return'
        WHEN t1.return_count BETWEEN 51 AND 100 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    TopReturningItems t1
JOIN 
    inventory inv ON inv.inv_item_sk = t1.sr_item_sk
JOIN 
    warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN 
    web_sales ws ON ws.ws_item_sk = t1.sr_item_sk AND ws.ws_sold_date_sk = (
        SELECT MAX(ws_sold_date_sk) 
        FROM web_sales 
        WHERE ws_item_sk = t1.sr_item_sk
    )
WHERE 
    (t1.return_count > 0 OR ws.ws_net_profit > 0)
    AND (ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_code = 'STANDARD') 
    OR ws.ws_ship_mode_sk IS NULL)
ORDER BY 
    total_return_amount DESC
LIMIT 50;
