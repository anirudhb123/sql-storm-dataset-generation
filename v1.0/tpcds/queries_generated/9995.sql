
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        i.i_category,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year >= 2021 
        AND d.d_year <= 2023
    GROUP BY 
        ws.ws_item_sk, 
        d.d_year, 
        d.d_month_seq, 
        c.cd_gender, 
        i.i_category, 
        ca.ca_state
), RankedSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, ca_state ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)

SELECT 
    d_year, 
    d_month_seq, 
    ca_state, 
    cd_gender, 
    i_category, 
    total_quantity, 
    total_sales
FROM 
    RankedSales
WHERE 
    sales_rank <= 5  
ORDER BY 
    d_year, 
    d_month_seq, 
    ca_state, 
    total_sales DESC;
