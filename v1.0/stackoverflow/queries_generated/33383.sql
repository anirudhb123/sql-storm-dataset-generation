WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL  -- Start with top-level posts

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        MAX(b.Date) AS LastBadgeDate
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
)
SELECT 
    ph.PostId,
    ph.Title AS PostTitle,
    ph.Level AS PostLevel,
    ua.DisplayName AS UserName,
    ua.TotalPosts,
    ua.TotalBounty,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.AcceptedAnswerId,
    ps.OwnerDisplayName
FROM RecursivePostHierarchy ph
JOIN UserActivity ua ON ph.OwnerUserId = ua.UserId
JOIN PostStatistics ps ON ph.PostId = ps.Id
WHERE ph.Level <= 2  -- Get only top level and first level of replies for simplicity
ORDER BY ps.Score DESC, ps.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Pagination for performance benchmarking
