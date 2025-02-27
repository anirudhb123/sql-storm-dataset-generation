WITH RecursivePostTree AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.AnswerCount,
        P.Score,
        P.OwnerUserId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        A.Id AS PostId,
        A.Title,
        A.ViewCount,
        A.CreationDate,
        A.AnswerCount,
        A.Score,
        A.OwnerUserId,
        Level + 1
    FROM 
        Posts A
    INNER JOIN 
        RecursivePostTree Q ON A.ParentId = Q.PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT B.Id) AS TotalBadges,
    AVG(P.Score) AS AvgScore,
    COUNT(DISTINCT C.Id) AS TotalComments,
    MAX(P.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    ROW_NUMBER() OVER(ORDER BY COALESCE(SUM(P.ViewCount), 0) DESC) AS Rank
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, '><')) AS TagName
    ) T ON TRUE
WHERE 
    U.Reputation > 1000
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING 
    COUNT(DISTINCT P.Id) > 5
ORDER BY 
    TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- The query aggregates data about users, their posts, badges, comments, 
-- and the associated tags. It uses a recursive CTE to build a tree of posts 
-- and allows ranking users based on their reputation and engagement metrics. 
-- It excludes users with less than 1000 reputation and only includes those 
-- with more than 5 posts.
