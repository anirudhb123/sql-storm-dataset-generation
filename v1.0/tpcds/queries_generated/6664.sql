
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        SUM(cs.total_sales) AS sales_by_demographic
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        CustomerSales cs ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ca.ca_state
),
RankedDemographics AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY sales_by_demographic DESC) AS sales_rank
    FROM 
        Demographics
)
SELECT 
    dd.cd_gender,
    dd.cd_marital_status,
    dd.ca_state,
    dd.sales_by_demographic,
    rd.sales_rank
FROM 
    RankedDemographics rd
JOIN 
    customer_demographics dd ON rd.cd_demo_sk = dd.cd_demo_sk
WHERE 
    rd.sales_rank <= 5
ORDER BY 
    dd.ca_state, rd.sales_rank;
