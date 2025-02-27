
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_date AS sales_date,
        i.i_item_desc,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk) AS order_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450807 AND 2450857 -- Random range for benchmarking
),
Refunds AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
),
Summary AS (
    SELECT 
        o.sales_date,
        o.i_item_desc,
        SUM(o.ws_quantity) AS total_quantity_sold,
        COALESCE(r.total_returned, 0) AS total_returned,
        SUM(o.ws_net_profit) AS total_profit
    FROM 
        SalesData o
    LEFT JOIN 
        Refunds r ON o.ws_order_number = r.wr_order_number
    GROUP BY 
        o.sales_date, o.i_item_desc
)
SELECT 
    s.sales_date,
    s.i_item_desc,
    s.total_quantity_sold,
    s.total_returned,
    s.total_profit,
    CASE 
        WHEN s.total_profit > 1000 THEN 'High Profit'
        WHEN s.total_profit > 500 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    Summary s
WHERE 
    s.total_quantity_sold > 0
ORDER BY 
    s.sales_date DESC,
    s.total_profit DESC
FETCH FIRST 100 ROWS ONLY;

WITH Heterogeneous AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        STRING_AGG(DISTINCT i.i_brand) AS unique_brands,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ca.ca_city IS NOT NULL
    GROUP BY 
        c.c_customer_id, ca.ca_city
)
SELECT 
    h.c_customer_id,
    h.ca_city,
    h.unique_brands,
    h.total_spending
FROM 
    Heterogeneous h
WHERE 
    h.total_spending IS NOT NULL
ORDER BY 
    h.total_spending DESC 
FETCH FIRST 50 ROWS ONLY;
