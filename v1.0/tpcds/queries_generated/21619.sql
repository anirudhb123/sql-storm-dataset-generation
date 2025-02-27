
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank,
        ws.ws_net_profit,
        ws.ws_sales_price,
        cd.cd_gender,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sales_price > 0
),
TopProfitableSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        AVG(tp.total_net_profit) AS avg_profit_per_item,
        SUM(tp.sales_count) AS total_sales_count
    FROM 
        TopProfitableSales tp
    JOIN 
        web_sales ws ON tp.ws_item_sk = ws.ws_item_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    COALESCE(SBS.ca_state, 'UNKNOWN') AS state,
    SBS.avg_profit_per_item,
    SBS.total_sales_count,
    RANK() OVER (ORDER BY SBS.avg_profit_per_item DESC) AS state_rank
FROM 
    (SELECT DISTINCT ca_state FROM customer_address) AS SBS
LEFT JOIN 
    SalesByState s ON SBS.ca_state = s.ca_state
ORDER BY 
    state_rank, state ASC;
