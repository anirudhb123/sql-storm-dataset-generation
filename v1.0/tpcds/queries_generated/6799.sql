
WITH RankedSales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_net_profit) AS total_net_profit, 
        COUNT(DISTINCT cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 365  -- assuming dates are in some valid range
    GROUP BY 
        cs_item_sk
),
TopProfitableItems AS (
    SELECT 
        r.cs_item_sk, 
        i.i_item_desc, 
        r.total_net_profit, 
        r.total_orders,
        (SELECT cc.cc_name 
         FROM call_center cc 
         JOIN store s ON cc.cc_call_center_sk = s.s_store_sk 
         WHERE s.s_store_sk = z.ss_store_sk) AS call_center_name
    FROM 
        RankedSales r
    JOIN 
        item i ON r.cs_item_sk = i.i_item_sk
    JOIN 
        store_sales z ON r.cs_item_sk = z.ss_item_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    item.i_item_desc, 
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(ss.ss_net_profit) AS total_store_profit,
    t.time,
    d.d_date
FROM 
    web_sales ws
JOIN 
    store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN 
    TopProfitableItems tpi ON ws.ws_item_sk = tpi.cs_item_sk
GROUP BY 
    item.i_item_desc, t.time, d.d_date
ORDER BY 
    total_web_profit DESC, total_store_profit DESC;
