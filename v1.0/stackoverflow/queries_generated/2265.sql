WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title, 
    p.CreationDate,
    p.Score,
    p.CommentCount,
    us.DisplayName AS OwnerDisplayName,
    us.Reputation,
    us.TotalBounties,
    ups.ReopenVotes,
    ups.CloseVotes
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserStats us ON us.UserId = u.Id
LEFT JOIN 
    ClosedPostStats ups ON p.PostId = ups.PostId
WHERE 
    p.RN = 1
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
