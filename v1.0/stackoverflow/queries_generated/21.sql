WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName, 
    u.Reputation, 
    up.BadgeCount, 
    up.AvgBounty, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    ph.CloseCount, 
    ph.ReopenCount
FROM 
    Users u
JOIN 
    UserReputation up ON u.Id = up.UserId
JOIN 
    RankedPosts rp ON u.Id = rp.PostId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    up.Reputation > 1000
    AND ph.CloseCount > 0 
ORDER BY 
    up.Reputation DESC, rp.CreationDate DESC
LIMIT 50;

WITH DuplicatePosts AS (
    SELECT 
        pl.PostId,
        p.Title,
        COUNT(pl.RelatedPostId) AS DuplicateCount
    FROM 
        PostLinks pl
    JOIN 
        Posts p ON pl.PostId = p.Id
    GROUP BY 
        pl.PostId, p.Title
    HAVING 
        COUNT(pl.RelatedPostId) > 1
)
SELECT 
    dp.Title, 
    dp.DuplicateCount, 
    COUNT(c.Id) AS CommentCount
FROM 
    DuplicatePosts dp
LEFT JOIN 
    Comments c ON dp.PostId = c.PostId
WHERE 
    EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = dp.PostId AND v.VoteTypeId = 2)
GROUP BY 
    dp.Title, dp.DuplicateCount
ORDER BY 
    dp.DuplicateCount DESC, CommentCount DESC;
