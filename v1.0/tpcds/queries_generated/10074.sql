
SELECT 
    ca.city AS Address_City,
    COUNT(DISTINCT c.customer_id) AS Customer_Count,
    AVG(cd.purchase_estimate) AS Average_Purchase_Estimate,
    SUM(ws.sales_price) AS Total_Sales_Amount
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca.city
ORDER BY 
    Total_Sales_Amount DESC;
