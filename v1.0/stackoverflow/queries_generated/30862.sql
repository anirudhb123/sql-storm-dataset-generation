WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalVotes,
        TotalComments,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM UserEngagement
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    p.Title AS TopPostTitle,
    p.Score AS TopPostScore,
    p.ViewCount AS TopPostViews,
    ph.CreationDate AS PostHistoryDate,
    pt.Name AS PostType,
    COALESCE(b.BadgeCount, 0) as BadgeCount
FROM TopUsers u
JOIN (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        pt.Name
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.Score > 0 
    ORDER BY p.Score DESC
    LIMIT 1
) p ON u.UserId = p.OwnerUserId
LEFT JOIN PostHistory ph ON ph.PostId = p.Id
LEFT JOIN (
    SELECT 
        UserId, COUNT(*) AS BadgeCount 
    FROM Badges 
    GROUP BY UserId
) b ON u.UserId = b.UserId
WHERE u.TotalPosts > 10 AND VoteRank <= 5  -- Engaged users with posts
ORDER BY u.TotalVotes DESC;
