WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        ParentId, 
        Title, 
        PostTypeId, 
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.ParentId, 
        p.Title, 
        p.PostTypeId, 
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastChangeDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBountiesGiven
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        C.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.AverageScore,
    COALESCE(RA.TotalComments, 0) AS RecentComments,
    COALESCE(RA.TotalBountiesGiven, 0) AS TotalBountiesGiven,
    PI.LastChangeDate,
    PI.HistoryTypes,
    COUNT(DISTINCT RPH.Id) AS TotalSubPosts
FROM 
    UserStatistics U
LEFT JOIN 
    PostHistoryInfo PI ON U.UserId = PI.PostId
LEFT JOIN 
    RecentActivity RA ON U.UserId = RA.UserId
LEFT JOIN 
    RecursivePostHierarchy RPH ON U.UserId = RPH.ParentId
GROUP BY 
    U.UserId, U.DisplayName, 
    RA.TotalComments, RA.TotalBountiesGiven, 
    PI.LastChangeDate, PI.HistoryTypes
ORDER BY 
    U.TotalPosts DESC, U.AverageScore DESC;
