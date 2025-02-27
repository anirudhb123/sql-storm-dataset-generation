
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerAddress AS (
    SELECT 
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ca.c_customer_id
    FROM 
        customer_address a
    JOIN 
        customer ca ON a.ca_address_sk = ca.c_current_addr_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(ca.ca_city, 'Unknown City') AS city,
    COALESCE(ca.ca_state, 'Unknown State') AS state,
    COALESCE(ca.ca_country, 'Unknown Country') AS country,
    tc.total_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerAddress ca ON tc.c_customer_id = ca.c_customer_id
ORDER BY 
    total_sales DESC;

WITH ReturnStats AS (
    SELECT 
        sr.returning_customer_sk,
        COUNT(sr.return_ticket_number) AS return_count,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(sr.return_qty) AS total_return_qty
    FROM 
        store_returns sr
    GROUP BY 
        sr.returning_customer_sk
),
ReturnDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.return_count,
        rs.total_return_amt,
        rs.total_return_qty
    FROM 
        customer c
    LEFT JOIN 
        ReturnStats rs ON c.c_customer_sk = rs.returning_customer_sk
)
SELECT 
    td.c_customer_id,
    td.c_first_name,
    td.c_last_name,
    COALESCE(td.return_count, 0) AS return_count,
    COALESCE(td.total_return_amt, 0.00) AS total_return_amt,
    COALESCE(td.total_return_qty, 0) AS total_return_qty,
    r.total_sales
FROM 
    ReturnDetails td
FULL OUTER JOIN 
    (SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales
     FROM 
        web_sales
     GROUP BY 
        ws_bill_customer_sk) r ON td.c_customer_id = r.ws_bill_customer_sk
ORDER BY 
    total_sales DESC, return_count DESC;
