
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(i.i_brand, 'Unknown') AS brand_info,
        COALESCE(i.i_class, 'Unknown') AS class_info
    FROM 
        item i
),
ReturnSums AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
AggregateResults AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_paid_inc_tax) AS avg_order_value,
        SUM(COALESCE(rs.total_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT CASE WHEN rs.total_returns > 0 THEN cs.cs_order_number END) AS returning_customer_orders
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        ReturnSums rs ON cs.cs_item_sk = rs.sr_item_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year
)
SELECT 
    ar.d_year,
    ar.total_orders,
    ar.total_net_profit,
    ar.avg_order_value,
    ar.total_returns,
    ar.returning_customer_orders,
    CASE WHEN ar.returning_customer_orders > 0 
        THEN ar.total_returns / ar.returning_customer_orders 
        ELSE 0 END AS avg_returns_per_returning_order,
    (SELECT LISTAGG(CONCAT(id.i_item_desc, ' (', id.brand_info, ')'), ', ')
     WITHIN GROUP (ORDER BY id.i_item_desc) 
     FROM ItemDetails id 
     JOIN RankedSales r ON id.i_item_sk = r.ws_item_sk
     WHERE r.rn <= 5) AS top_items_info
FROM 
    AggregateResults ar;
