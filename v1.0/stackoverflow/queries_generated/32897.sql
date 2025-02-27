WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        (p.Score > 10 OR p.ViewCount > 100)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS RankByReputation
    FROM 
        Users u
    WHERE 
        u.Reputation >= 1000
), 
PostActivity AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ActivityCount,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 19)  -- Closed, Reopened, Deleted, Protected
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViewCount,
    p.Score AS PostScore,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    u.Views AS OwnerViews,
    pc.ActivityCount AS PostActivityCount,
    pc.LastActivityDate AS LastPostActivity,
    CASE
        WHEN pc.LastActivityDate IS NULL THEN 'No activity'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostActivity pc ON p.PostId = pc.PostId
WHERE 
    p.RankByScore <= 5  -- Top 5 posts per user
    AND u.Id IN (SELECT UserId FROM TopUsers WHERE RankByReputation <= 10)  -- Top 10 users
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC;
