
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        RankedSales.total_quantity_sold,
        RankedSales.total_sales,
        RankedSales.ws_item_sk,
        RankedSales.rank
    FROM
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.rank <= 5
)
SELECT 
    ta.i_item_id,
    ta.i_item_desc,
    ta.total_quantity_sold,
    ta.total_sales,
    CA.ca_city,
    CE.cd_gender,
    CE.cd_marital_status
FROM 
    TopSales ta
JOIN 
    customer c ON c.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = ta.ws_item_sk)
JOIN 
    customer_demographics CE ON c.c_current_cdemo_sk = CE.cd_demo_sk
JOIN 
    customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
WHERE 
    CA.ca_city IN ('New York', 'Los Angeles', 'Chicago')
ORDER BY 
    ta.total_sales DESC;
