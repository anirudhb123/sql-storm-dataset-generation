WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountiesAwarded,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
    GROUP BY 
        ph.PostId
),
PostLinkStats AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)

SELECT 
    p.PostId,
    p.Title,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
    u.Reputation,
    COALESCE(badge.BadgeCount, 0) AS BadgeCount,
    COALESCE(closed.CloseCount, 0) AS CloseCount,
    COALESCE(pl.LinkedPostCount, 0) AS LinkedPostCount,
    CASE 
        WHEN p.Score > 10 THEN 'High Score'
        WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation badge ON u.Id = badge.UserId
LEFT JOIN 
    ClosedPostHistory closed ON p.PostId = closed.PostId
LEFT JOIN 
    PostLinkStats pl ON p.PostId = pl.PostId
WHERE 
    p.PostRank = 1
ORDER BY 
    u.Reputation DESC, 
    p.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;

-- Adding a bizarre and obscure NULL logic condition to demonstrate. If the user has no badges or no votes, consider the reputation as NULL
SELECT 
    *,
    CASE 
        WHEN BadgeCount IS NULL AND TotalBountiesAwarded IS NULL 
        THEN NULL
        ELSE Reputation 
    END AS AdjustedReputation
FROM 
    (SELECT ... ) AS main_query; -- Assume the above query is named main_query
