
WITH RankedSales AS (
    SELECT 
        ws.sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.sold_date_sk, 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        RankedSales.total_quantity, 
        RankedSales.total_profit
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.rank <= 10
),
SalesSummary AS (
    SELECT 
        ca_state, 
        SUM(ts.total_quantity) AS state_total_quantity, 
        SUM(ts.total_profit) AS state_total_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        TopSales ts ON c.c_customer_sk = ts.ws_bill_customer_sk
    GROUP BY 
        ca_state
)
SELECT 
    ss.ca_state, 
    ss.state_total_quantity, 
    ss.state_total_profit,
    RANK() OVER (ORDER BY ss.state_total_profit DESC) AS state_profit_rank
FROM 
    SalesSummary ss
ORDER BY 
    ss.state_total_profit DESC;
