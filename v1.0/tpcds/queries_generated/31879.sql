
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) + s.total_quantity,
        SUM(ws_net_profit) + s.total_net_profit
    FROM 
        web_sales s
    INNER JOIN 
        SalesCTE st ON s.ws_sold_date_sk = st.ws_sold_date_sk + 1 
        AND s.ws_item_sk = st.ws_item_sk
    GROUP BY 
        s.ws_sold_date_sk, s.ws_item_sk
),
RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(st.total_quantity) AS total_quantity,
        SUM(st.total_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(st.total_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        SalesCTE st ON c.c_customer_sk = st.ws_item_sk
    GROUP BY 
        c.c_customer_id, c.c_customer_sk
)
SELECT 
    r.c_customer_id,
    r.total_quantity,
    r.total_net_profit,
    COALESCE(CASE 
        WHEN r.profit_rank <= 10 THEN 'Top 10'
        ELSE 'Other' 
    END, 'No Data') AS rank_category
FROM 
    RankedSales r
WHERE 
    r.total_quantity > 100
    AND (r.total_net_profit IS NOT NULL OR r.total_quantity IS NOT NULL)
ORDER BY 
    r.total_net_profit DESC, r.total_quantity ASC;
