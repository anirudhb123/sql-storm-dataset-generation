
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        cs.cs_item_sk, 
        SUM(cs.cs_quantity) AS total_sales_quantity, 
        SUM(cs.cs_sales_price) AS total_sales_value,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) - 30 
                               AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND i.i_current_price > 20.00
    GROUP BY 
        ws.web_site_id, cs.cs_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT s.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    sd.web_site_id,
    sd.total_sales_quantity,
    sd.total_sales_value,
    sd.average_profit,
    cd.total_purchases,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON sd.total_sales_quantity > 50
ORDER BY 
    sd.total_sales_value DESC, cd.total_purchases DESC;
