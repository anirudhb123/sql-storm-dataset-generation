
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) as rank_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
), CustomerWithReturns AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        MAX(cr_refunded_customer_sk) AS last_refunded_customer_sk
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
), TotalSalesByWebsite AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_tax > 100.00
    GROUP BY 
        ws.web_site_sk
), HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1985 -- Customers born before 1985
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_sales_price) > 1000.00
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), OuterJoinExample AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS city_customers,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS city_returns,
        SUM(ws.ws_net_paid) AS city_revenue
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_returns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_city
), FinalResults AS (
    SELECT 
        rc.web_site_sk,
        rc.order_number,
        rc.ws_sales_price,
        c.total_returns,
        t.total_sales,
        h.c_first_name,
        h.c_last_name,
        d.customer_count,
        o.city_customers,
        o.city_returns,
        o.city_revenue
    FROM 
        RankedSales rc
    JOIN 
        CustomerWithReturns c ON rc.web_site_sk = c.c_customer_sk
    JOIN 
        TotalSalesByWebsite t ON rc.web_site_sk = t.web_site_sk
    JOIN 
        HighValueCustomers h ON c.c_customer_sk = h.c_customer_sk
    JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        OuterJoinExample o ON rc.web_site_sk = o.ca_city
    WHERE 
        (c.total_returns > 0 OR h.order_count > 5)
        AND (rc.rank_price = 1 OR d.customer_count > 5)
)
SELECT * FROM FinalResults
WHERE total_sales IS NOT NULL
ORDER BY city_revenue DESC NULLS LAST;
