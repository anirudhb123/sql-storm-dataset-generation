
SELECT 
    U.Id AS UserId,
    U.DisplayName AS UserName,
    COUNT(P.Id) AS PostCount,
    SUM(P.ViewCount) AS TotalViews,
    SUM(P.Score) AS TotalScore,
    AVG(DATEDIFF(SECOND, '1970-01-01', P.CreationDate)) AS AveragePostCreationDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostCount DESC;
