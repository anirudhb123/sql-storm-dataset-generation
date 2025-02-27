WITH RecursiveUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        1 AS Level
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 500
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        PP.Id,
        PP.Title,
        PP.CreationDate,
        PP.Score,
        PP.ViewCount,
        RP.Level + 1
    FROM 
        RecursiveUserPosts RP
    JOIN 
        Posts PP ON RP.PostId = PP.ParentId
)
SELECT 
    U.UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    SUM(P.ViewCount) AS TotalViews,
    SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS PositiveScores,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM 
    RecursiveUserPosts U
JOIN 
    Posts P ON U.PostId = P.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(P.Tags, ',')) AS TagName
    ) T ON TRUE
GROUP BY 
    U.UserId, U.DisplayName
HAVING 
    COUNT(P.Id) > 10
ORDER BY 
    TotalPosts DESC, TotalViews DESC
FETCH FIRST 10 ROWS ONLY;

-- Subquery for user badges
SELECT 
    U.UserId,
    U.DisplayName,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    (SELECT 
         DISTINCT Id AS UserId, DisplayName FROM Users) U
LEFT JOIN 
    (SELECT 
         UserId, COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     WHERE 
         Class = 1 -- Only gold badges
     GROUP BY 
         UserId) B ON U.UserId = B.UserId
ORDER BY 
    BadgeCount DESC;

This query performs several complex operations:
1. A recursive Common Table Expression (CTE) to find users who have posted questions and their associated posts and answers up to a hierarchy level.
2. A summary of total posts, views, and positive scores for each user who has more than 10 posts, along with the concatenated tags they used.
3. A left join with a subquery to count the number of gold badges each user has, ensuring it returns all users regardless of the badge count. 
4. Outputs only the top 10 users based on the total number of posts and views.
