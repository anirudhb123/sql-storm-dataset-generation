WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.Score, 0) AS AdjustedScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(p.Score, 0) DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
        (SELECT SUM(v.BountyAmount) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 8) AS TotalBounties
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- 10 indicates Post Closed, 11 indicates Post Reopened
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(uc.AdjustedScore, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            p.Id,
            COALESCE(p.Score, 0) AS AdjustedScore
        FROM 
            Posts p) uc ON p.Id = uc.Id
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    up.PostsCount,
    up.TotalScore,
    SUM(COALESCE(cp.CloseReason, 'No Close Reason')) AS CloseReasons,
    SUM(CASE WHEN r.Rank <= 10 THEN 1 ELSE 0 END) AS TopRankedPosts
FROM 
    UserPostStats up
JOIN 
    Users u ON up.UserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON cp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN 
    RankedPosts r ON r.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
GROUP BY 
    u.DisplayName, up.PostsCount, up.TotalScore
HAVING 
    COUNT(DISTINCT u.Id) > 1 AND SUM(up.TotalScore) > 0
ORDER BY 
    TotalScore DESC, PostsCount DESC
LIMIT 100;
