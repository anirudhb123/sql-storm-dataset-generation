
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ws.ws_sold_date_sk
), TopCustomers AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.total_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank_profit <= 10
), SalesByDate AS (
    SELECT 
        dd.d_date_id,
        dd.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_date_id, dd.d_year
), CustomerSalesAnalysis AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        sbd.d_year,
        sbd.total_net_profit,
        RANK() OVER (ORDER BY sbd.total_net_profit DESC) AS year_rank
    FROM 
        TopCustomers tc
    JOIN 
        SalesByDate sbd ON tc.c_customer_id = tc.c_customer_id
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cda.cd_purchase_estimate) AS average_purchase_estimate,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_sales,
    MAX(ws.ws_sales_price) AS max_price
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cda ON c.c_current_cdemo_sk = cda.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' AND
    (cda.cd_marital_status = 'M' OR cda.cd_marital_status IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(COALESCE(ws.ws_net_paid, 0)) > 10000;
