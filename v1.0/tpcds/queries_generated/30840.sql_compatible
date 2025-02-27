
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        cs.sold_date_sk, 
        cs.item_sk, 
        SUM(cs.quantity) + sc.total_quantity, 
        SUM(cs.net_profit) + sc.total_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        SalesCTE sc ON cs.sold_date_sk = sc.ws_sold_date_sk AND cs.item_sk = sc.ws_item_sk
    GROUP BY 
        cs.sold_date_sk, 
        cs.item_sk
),
AddressCTE AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state
),
FinalSales AS (
    SELECT 
        s.ws_sold_date_sk, 
        s.ws_item_sk,
        s.total_quantity, 
        s.total_net_profit,
        a.ca_city,
        a.ca_state,
        RANK() OVER (PARTITION BY a.ca_state ORDER BY s.total_net_profit DESC) AS profit_rank
    FROM 
        SalesCTE s
    JOIN 
        AddressCTE a ON a.customer_count > 0
)
SELECT 
    d.d_date_id,
    COALESCE(fs.total_quantity, 0) AS total_quantity,
    COALESCE(fs.total_net_profit, 0) AS total_net_profit,
    fs.ca_city,
    fs.ca_state
FROM 
    date_dim d
LEFT JOIN 
    FinalSales fs ON d.d_date_sk = fs.ws_sold_date_sk
WHERE 
    d.d_year = 2023 
    AND (fs.profit_rank IS NULL OR fs.profit_rank <= 10)
ORDER BY 
    d.d_date_id, 
    fs.ca_city;
