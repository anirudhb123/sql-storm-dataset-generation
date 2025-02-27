WITH RecursivePostHierarchy AS (
    -- Recursive CTE to build a hierarchy of posts and their answers
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        P.OwnerUserId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Selecting only questions
    
    UNION ALL
    
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        P.OwnerUserId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
)
, UserActivity AS (
    -- Aggregating user activity related to posts, badges, and votes
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COUNT(DISTINCT V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
, ClosingPosts AS (
    -- Filtering for posts that have been closed
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 -- Closed posts
)
SELECT 
    U.DisplayName,
    UP.TotalViews,
    UP.TotalBadges,
    UP.TotalVotes,
    COUNT(DISTINCT PH.PostId) AS ClosedPostsCount,
    COUNT(DISTINCT R.PostId) AS AnswerCount,
    COUNT(DISTINCT CASE WHEN PH.Comment IS NOT NULL THEN PH.PostId END) AS CommentsOnClosedPosts
FROM 
    UserActivity UP
LEFT JOIN 
    RecursivePostHierarchy R ON UP.UserId = R.OwnerUserId
LEFT JOIN 
    ClosingPosts PH ON R.PostId = PH.PostId
GROUP BY 
    U.DisplayName, UP.TotalViews, UP.TotalBadges, UP.TotalVotes
HAVING 
    SUM(UP.TotalViews) > 1000 -- Example predicate to filter users based on total views
ORDER BY 
    TotalVotes DESC, TotalViews DESC;
