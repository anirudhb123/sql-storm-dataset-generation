WITH RecursiveTagCTE AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        T.Count,
        1 AS Depth
    FROM 
        Tags T
    WHERE 
        T.IsRequired = 1
    
    UNION ALL
    
    SELECT 
        TL.RelatedPostId AS TagId,
        T.TagName,
        T.Count,
        RC.Depth + 1
    FROM 
        PostLinks AS PL
    JOIN 
        Posts AS P ON PL.PostId = P.Id
    JOIN 
        Tags AS T ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        RecursiveTagCTE AS RC ON PL.RelatedPostId = RC.TagId
)
, UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.Upvotes,
    U.Downvotes,
    U.BadgeCount,
    COALESCE(RTC.TagId, 0) AS RelatedTagId,
    COALESCE(RTC.TagName, 'No Related Tag') AS RelatedTagName,
    RTC.Depth
FROM 
    UserActivity U
LEFT JOIN 
    RecursiveTagCTE RTC ON U.UserId = (SELECT DISTINCT OwnerUserId FROM Posts WHERE Tags LIKE '%' || RTC.TagName || '%')
WHERE 
    U.PostCount > 0
ORDER BY 
    U.Upvotes DESC, U.Downvotes ASC, U.BadgeCount DESC
LIMIT 100;

-- Explanation:
-- The query retrieves user statistics including post counts, upvotes, downvotes, and badge counts.
-- It combines those statistics with a recursive Common Table Expression to fetch related tags.
-- The outer query joins user activity with the recursive CTE to find tags related to the users' posts.
-- The result includes the user ID, display name, and other statistics, filtered by users with post counts greater than zero,
-- ordered by their upvotes, downvotes, and badge counts respectively.
