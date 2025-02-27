WITH RecursiveTagHierarchy AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        1 AS Level,
        t.Count
    FROM Tags t
    WHERE t.IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        Level + 1,
        t.Count
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy rth ON t.WikiPostId = rth.TagId
), 

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostType,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS RevisionCount
        FROM PostHistory
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
)

SELECT 
    u.DisplayName,
    ua.PostsCount,
    ua.CommentsCount,
    ua.TotalBounties,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.PostType,
    STRING_AGG(rt.TagName, ', ') AS RelatedTags
FROM UserActivity ua
JOIN PostDetails pd ON pd.PostId = ANY(
    SELECT p.Id
    FROM Posts p
    WHERE p.OwnerUserId = ua.UserId
) 
LEFT JOIN PostLinks pl ON pd.PostId = pl.PostId
LEFT JOIN Tags rt ON pl.RelatedPostId = rt.Id
GROUP BY u.DisplayName, ua.PostsCount, ua.CommentsCount, ua.TotalBounties, pd.Title, pd.CreationDate, pd.ViewCount, pd.PostType
ORDER BY ua.PostsCount DESC, ua.CommentsCount DESC;

-- Performance considerations:
-- 1. Recursive CTE to handle multiple tags for posts.
-- 2. Window functions for user activity summarization.
-- 3. Aggregation with STRING_AGG to combine related tags.
-- 4. Nullable joins and COALESCE to handle missing values.
-- 5. Using subquery in the main join for clarity of user post associations.
-- 6. Grouping and ordering to structure results for better readability.
