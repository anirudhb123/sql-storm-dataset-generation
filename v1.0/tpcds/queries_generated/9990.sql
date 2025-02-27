
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy IN (6, 7)  -- June and July
        AND i.i_current_price > 20
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
SalesByRegion AS (
    SELECT 
        ca_state,
        SUM(total_sales) AS state_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.web_site_sk
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    state_sales,
    RANK() OVER (ORDER BY state_sales DESC) AS state_rank
FROM 
    SalesByRegion
WHERE 
    state_sales > 10000
ORDER BY 
    state_rank;
