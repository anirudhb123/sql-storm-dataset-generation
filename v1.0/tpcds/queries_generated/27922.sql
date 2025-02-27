
SELECT 
    r.r_reason_desc AS Return_Reason,
    COUNT(cr.cr_return_quantity) AS Total_Returned_Quantity,
    SUM(cr.cr_return_amount) AS Total_Return_Amount,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS Unique_Customers,
    AVG(cr.cr_return_ship_cost) AS Average_Return_Ship_Cost,
    AVG(cr.cr_fee) AS Average_Return_Fee,
    DENSE_RANK() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS Return_Rank
FROM 
    catalog_returns cr
JOIN 
    reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN 
    item i ON cr.cr_item_sk = i.i_item_sk
JOIN 
    store s ON cr.cr_store_sk = s.s_store_sk
WHERE 
    cr.cr_returned_date_sk > (
        SELECT MAX(d.d_date_sk) - 90 
        FROM date_dim d
    ) 
GROUP BY 
    r.r_reason_desc 
HAVING 
    COUNT(cr.cr_return_quantity) > 10
ORDER BY 
    Total_Return_Amount DESC;
