
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS sales_count,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerPurchases AS (
    SELECT 
        ca.ca_state,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ca.ca_state, cd.cd_gender
)
SELECT 
    cp.ca_state,
    cp.cd_gender,
    cp.total_quantity,
    cp.total_spent,
    ts.sales_count,
    ts.total_profit
FROM 
    CustomerPurchases cp
LEFT JOIN 
    TopSales ts ON ts.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_order_number = (SELECT MAX(ws_order_number) FROM web_sales))
ORDER BY 
    cp.ca_state, 
    cp.cd_gender;
