WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalUpvotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS TotalDownvotes,
        SUM(CASE WHEN B.Name IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        (SELECT COUNT(*) 
         FROM Posts 
         WHERE OwnerUserId = U.Id AND CreationDate >= NOW() - INTERVAL '1 YEAR') AS RecentPostsLastYear
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(a.CommentCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) pc ON P.Id = pc.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON P.Id = a.ParentId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 DAY'
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.CommentCount,
    PD.AnswerCount,
    CASE 
        WHEN UA.Reputation > 1000 THEN 'Expert' 
        WHEN UA.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate' 
        ELSE 'Novice' 
    END AS ExpertiseLevel,
    ARRAY_AGG( DISTINCT B.Name ) AS BadgeNames
FROM 
    UserActivity UA
LEFT JOIN 
    PostDetails PD ON UA.UserId = PD.PostId
LEFT JOIN 
    Badges B ON UA.UserId = B.UserId
WHERE 
    (UA.Reputation IS NOT NULL OR UA.Reputation > 0) -- non-null reputation check
    AND (NVL(PD.ViewCount, 0) - NVL(PD.CommentCount, 0) > 10 OR PD.PostId IS NULL)
    AND PD.rn <= 3 -- Limit to a maximum of 3 posts per user
GROUP BY 
    UA.UserId, UA.DisplayName, UA.Reputation, PD.PostId, PD.Title, PD.CreationDate, PD.Score, PD.ViewCount, PD.CommentCount, PD.AnswerCount
ORDER BY 
    UA.Reputation DESC, PD.Score DESC
LIMIT 50;

This SQL query combines several interesting constructs: 
- **Common Table Expressions (CTEs)** are used to calculate user activity and derive post details.
- **Correlated subqueries** fetch the count of recent posts within the last year for each user.
- **Window functions** like `ROW_NUMBER()` are utilized to limit the posts fetched per user.
- There’s a conditional case statement to classify expertise levels based on user reputation.
- **Outer joins** ensure users are included even if they have no posts.
- **NULL handling** with `COALESCE` and handling of reputation-related predicates increases robustness. 
- The `ARRAY_AGG` function collects distinct badge names into an array.
- The query integrates various filtering and aggregation techniques to yield insightful results in a single analysis run.
