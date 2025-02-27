
WITH Address_Counts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city
),

Customer_Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_dep_count) AS avg_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),

Date_Yearly_Sales AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_sales_profit
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),

Item_Details AS (
    SELECT 
        i_category,
        AVG(i_current_price) AS avg_price,
        MAX(i_current_price) AS max_price,
        MIN(i_current_price) AS min_price
    FROM 
        item
    GROUP BY 
        i_category
)

SELECT 
    AC.ca_city,
    AC.address_count,
    AC.street_types,
    CD.cd_gender,
    CD.demographic_count,
    CD.avg_dependencies,
    DY.d_year,
    DY.total_sales_profit,
    ID.i_category,
    ID.avg_price,
    ID.max_price,
    ID.min_price
FROM 
    Address_Counts AC
JOIN 
    Customer_Demographics CD ON AC.address_count > 1000
JOIN 
    Date_Yearly_Sales DY ON DY.total_sales_profit > 1000000
JOIN 
    Item_Details ID ON ID.avg_price < 50
ORDER BY 
    AC.address_count DESC, 
    CD.demographic_count DESC, 
    DY.d_year DESC;
