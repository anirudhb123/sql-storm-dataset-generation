
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
TopSales AS (
    SELECT 
        ca_state,
        SUM(total_sales) AS state_sales
    FROM 
        SalesCTE sc
    JOIN 
        customer c ON sc.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        sc.rank <= 10
    GROUP BY 
        ca_state
),
DateRanges AS (
    SELECT 
        d_year,
        d_month_seq,
        d_week_seq,
        COUNT(DISTINCT ws_order_number) AS number_of_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d_year, d_month_seq, d_week_seq
)
SELECT 
    t.state_sales,
    dr.d_year,
    dr.d_month_seq,
    dr.d_week_seq,
    dr.number_of_orders
FROM 
    TopSales t
FULL OUTER JOIN 
    DateRanges dr ON t.state_sales IS NOT NULL
WHERE 
    t.state_sales > (SELECT AVG(state_sales) FROM TopSales)
ORDER BY 
    t.state_sales DESC, dr.d_year DESC, dr.number_of_orders DESC;
