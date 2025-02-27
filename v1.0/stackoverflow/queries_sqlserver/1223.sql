
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(MONTH, 6, 0)
        AND p.Score > 0
),
RecentUsers AS (
    SELECT TOP 10
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts pp WHERE pp.OwnerUserId = u.Id AND pp.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(MONTH, 6, 0)) AS RecentPostsCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 100
    ORDER BY 
        u.CreationDate DESC
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ru.DisplayName AS TopUser,
    ru.Reputation,
    COALESCE(pv.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pv.Downvotes, 0) AS TotalDownvotes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentUsers ru ON rp.OwnerUserId = ru.UserId
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    rp.PostRank = 1
    AND ru.RecentPostsCount > 0
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
