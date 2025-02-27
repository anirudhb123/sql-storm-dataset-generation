
WITH RECURSIVE SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        1 AS level
    FROM
        web_sales ws
    WHERE
        ws.ws_order_number IN (SELECT DISTINCT sr_ticket_number FROM store_returns)
    
    UNION ALL

    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity + sd.ws_quantity,
        ws.ws_net_profit + sd.ws_net_profit,
        sd.level + 1
    FROM
        web_sales ws
    JOIN
        SalesData sd ON ws.ws_item_sk = sd.ws_item_sk
    WHERE
        sd.level < 5
),
AggregateSales AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month AS sales_month,
        SUM(sd.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT sd.ws_item_sk) AS total_unique_items
    FROM 
        SalesData sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(sd.ws_net_profit) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        SalesData sd ON ws.ws_item_sk = sd.ws_item_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    a.sales_year,
    a.sales_month,
    a.total_net_profit,
    a.total_unique_items,
    COALESCE(cs.customer_count, 0) AS total_customers,
    COALESCE(cs.total_sales, 0) AS total_sales_by_gender
FROM 
    AggregateSales a
LEFT JOIN 
    CustomerStats cs ON a.sales_year = EXTRACT(YEAR FROM CURRENT_DATE) - cs.customer_count
ORDER BY 
    a.sales_year, a.sales_month;
