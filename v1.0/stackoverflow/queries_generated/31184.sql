WITH RecursivePostHierarchy AS (
    -- Recursive CTE to gather parent/child structure of posts
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        RP.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RP ON P.ParentId = RP.PostId
),
UserPostStats AS (
    -- Aggregating user post statistics (counts for various metrics)
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        COUNT(PH.Id) AS ChangeCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId, PH.CreationDate
),
RecentPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        MAX(PH.CreationDate) AS LastEditDate,
        PH.ChangeCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistorySummary PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Recent posts in the last month
    GROUP BY 
        P.Id, P.Title
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT PH.PostId) AS ActivePostCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts
    FROM 
        Users U
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

-- Final Query: Combining all the stats with some filtering and ordering
SELECT 
    U.DisplayName,
    UP.TotalPosts,
    UP.Questions,
    UP.Answers,
    UActivity.ActivePostCount,
    UActivity.ClosedPosts,
    UActivity.ReopenedPosts,
    RP.PostId AS RelatedPost,
    RP.Title AS RelatedPostTitle,
    RP.Level AS PostLevel,
    RPS.LastEditDate,
    RPS.ChangeCount
FROM 
    UserPostStats UP
LEFT JOIN 
    UserActivity UActivity ON UP.UserId = UActivity.UserId
LEFT JOIN 
    RecursivePostHierarchy RP ON RP.PostId = UActivity.ActivePostCount
LEFT JOIN 
    RecentPostStats RPS ON UP.UserId = RPS.PostId
WHERE 
    UP.TotalPosts > 10 
    AND UP.UpVotes > UP.DownVotes 
ORDER BY 
    UP.TotalPosts DESC,
    UP.Reputation ASC;
