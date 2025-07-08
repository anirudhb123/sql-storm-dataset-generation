WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND ws.ws_sold_date_sk BETWEEN 2459560 AND 2459560 + 365  
),
TopSales AS (
    SELECT
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items_sold
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 3 
    GROUP BY 
        rs.ws_order_number
),
SalesByMonth AS (
    SELECT 
        d.d_month_seq,
        SUM(ts.total_sales) AS monthly_sales,
        COUNT(ts.unique_items_sold) AS total_unique_items
    FROM 
        TopSales ts
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT ws_sold_date_sk FROM web_sales ws WHERE ws.ws_order_number = ts.ws_order_number LIMIT 1)
    GROUP BY 
        d.d_month_seq
)
SELECT 
    d.d_month_seq,
    COALESCE(SUM(sb.monthly_sales), 0) AS total_monthly_sales,
    COALESCE(SUM(sb.total_unique_items), 0) AS total_unique_sales_items
FROM 
    date_dim d
LEFT JOIN 
    SalesByMonth sb ON d.d_month_seq = sb.d_month_seq
WHERE 
    d.d_year = 2001
GROUP BY 
    d.d_month_seq
ORDER BY 
    d.d_month_seq;