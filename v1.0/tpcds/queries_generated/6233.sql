
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerSegment AS (
    SELECT 
        cd.cd_gender,
        cd.cd_income_band_sk,
        AVG(rs.total_profit) AS avg_profit
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.cs_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = c.c_customer_sk)
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_income_band_sk
),
SalesByRegion AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ca.ca_state
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    cs.cd_gender,
    cs.cd_income_band_sk,
    cs.avg_profit,
    sr.ca_state,
    sr.total_quantity AS region_quantity,
    sr.total_profit AS region_profit
FROM 
    TopItems ti
JOIN 
    CustomerSegment cs ON cs.avg_profit > 0
JOIN 
    SalesByRegion sr ON sr.total_profit > 0
ORDER BY 
    ti.total_profit DESC, 
    cs.avg_profit DESC;
