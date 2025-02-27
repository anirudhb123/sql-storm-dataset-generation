
SELECT 
    U.DisplayName, 
    COUNT(P.Id) AS TotalPosts, 
    SUM(P.ViewCount) AS TotalViews
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
