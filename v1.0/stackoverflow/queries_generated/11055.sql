-- Benchmarking query to analyze post volumes, average scores, and user activity within the Stack Overflow schema

WITH PostStatistics AS (
    SELECT 
        Pt.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    INNER JOIN 
        PostTypes Pt ON P.PostTypeId = Pt.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'  -- analyzing posts created in the last year
    GROUP BY 
        Pt.Name
),

UserStatistics AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.DisplayName
)

SELECT 
    PS.PostType,
    PS.PostCount,
    PS.AverageScore,
    PS.TotalViews,
    US.DisplayName,
    US.PostsCreated,
    US.TotalBounty
FROM 
    PostStatistics PS
CROSS JOIN 
    UserStatistics US
ORDER BY 
    PS.PostCount DESC, 
    US.PostsCreated DESC;
