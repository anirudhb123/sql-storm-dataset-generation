WITH RECURSIVE PostHierarchy AS (
    SELECT Id, Title, ParentId, CreationDate, 1 as Level
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.Title, p.ParentId, p.CreationDate, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AcceptedCount, 0) AS AcceptedCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) as VoteCount
        FROM Votes
        WHERE VoteTypeId IN (2, 3) -- upvotes and downvotes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) as CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) as AcceptedCount
        FROM Posts
        WHERE PostTypeId = 1 AND AcceptedAnswerId IS NOT NULL
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
),
UserActivity AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT
        ph.Id,
        ph.Title,
        ph.CreationDate,
        ps.VoteCount,
        ps.CommentCount,
        ps.AcceptedCount,
        ua.DisplayName AS OwnerDisplayName,
        ua.TotalPosts,
        ua.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS RecentRank
    FROM PostHierarchy ph
    JOIN PostStats ps ON ph.Id = ps.Id
    JOIN Users u ON ps.OwnerUserId = u.Id
    JOIN UserActivity ua ON u.Id = ua.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.VoteCount,
    rp.CommentCount,
    rp.AcceptedCount,
    rp.OwnerDisplayName,
    rp.TotalPosts,
    rp.TotalScore
FROM RecentPosts rp
WHERE rp.RecentRank <= 10
ORDER BY rp.CreationDate DESC;

-- Additional stats for empty and populated ParentIds
SELECT 
    CASE 
        WHEN p.ParentId IS NULL THEN 'No Parent'
        ELSE 'Has Parent'
    END AS ParentStatus,
    COUNT(*) AS PostCount
FROM Posts p
GROUP BY p.ParentId;

-- Output total hierarchy levels of posts
SELECT Level, COUNT(*) AS PostCount
FROM PostHierarchy
GROUP BY Level
ORDER BY Level;
