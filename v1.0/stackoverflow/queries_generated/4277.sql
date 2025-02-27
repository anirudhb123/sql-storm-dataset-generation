WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    COALESCE(rp.Title, 'No Posts') AS Title,
    COALESCE(rp.Score, 0) AS Score,
    COALESCE(rp.ViewCount, 0) AS ViewCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.LastClosedDate, 'Never') AS LastClosedDate,
    CASE 
        WHEN rp.PostRank IS NOT NULL THEN 'Top Post'
        ELSE 'No Top Post'
    END AS PostStatus
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, up.DisplayName ASC;
