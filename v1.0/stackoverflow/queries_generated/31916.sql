WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Select questions only
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2 -- Answers only
        GROUP BY ParentId
    ) a ON a.ParentId = p.Id
    LEFT JOIN LATERAL (
        SELECT TagName
        FROM Tags t
        WHERE t.ExcerptPostId = p.Id
        UNION
        SELECT TagName
        FROM Tags t
        WHERE t.WikiPostId = p.Id
    ) t ON true
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.Reputation
)
SELECT 
    up.UserId,
    up.Reputation,
    up.TotalPosts,
    up.TotalBounty,
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.AnswerCount,
    rph.Level AS PostHierarchyLevel,
    string_agg(DISTINCT t.TagName, ', ') AS Tags
FROM UserReputation up
JOIN PostMetrics pm ON pm.OwnerUserId = up.UserId
LEFT JOIN RecursivePostHierarchy rph ON rph.PostId = pm.PostId
LEFT JOIN LATERAL (
    SELECT DISTINCT t.TagName
    FROM Tags t
    JOIN Posts p ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    WHERE p.Id = pm.PostId
) t ON true
WHERE up.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
  AND pm.Score > 0
GROUP BY up.UserId, up.Reputation, up.TotalPosts, up.TotalBounty, pm.PostId, pm.Title, pm.CreationDate, pm.Score, pm.ViewCount, pm.CommentCount, pm.AnswerCount, rph.Level
ORDER BY up.Reputation DESC, pm.CreationDate DESC;
