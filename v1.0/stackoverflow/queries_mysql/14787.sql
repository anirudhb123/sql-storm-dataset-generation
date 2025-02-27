
WITH PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        PT.Name
)

SELECT 
    PostType,
    PostCount,
    AverageScore,
    AverageUserReputation
FROM 
    PostStats
ORDER BY 
    PostCount DESC;
