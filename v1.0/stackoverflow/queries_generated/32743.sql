WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        OwnerUserId,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT v.Id) AS VotesCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
TopEngagedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCount,
        CommentsCount,
        VotesCount,
        TotalBounty,
        RANK() OVER (ORDER BY PostsCount + CommentsCount + VotesCount DESC) AS EngagementRank
    FROM UserEngagement
    WHERE (PostsCount + CommentsCount + VotesCount) > 0
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PopularityRank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    u.DisplayName AS UserName,
    ph.PostId,
    ph.HistoryCount,
    ph.ClosureCount,
    tp.Title AS TopPostTitle,
    tp.ViewCount AS TopPostViewCount,
    tp.Score AS TopPostScore,
    r.Level AS PostLevel
FROM TopEngagedUsers u
JOIN PostHistoryStats ph ON u.UserId = ph.PostId
JOIN TopPosts tp ON ph.PostId = tp.Id
JOIN RecursivePostHierarchy r ON ph.PostId = r.Id
WHERE u.EngagementRank <= 10
ORDER BY u.PostsCount DESC, tp.Score DESC;
