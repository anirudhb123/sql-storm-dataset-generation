WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(ubi.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(ubi.BadgeNames, 'No badges') AS UserBadges,
    COALESCE(phi.LastClosedDate, 'Never') AS LastClosed,
    COALESCE(phi.LastReopenedDate, 'Never') AS LastReopened,
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ubi ON rp.OwnerUserId = ubi.UserId
LEFT JOIN 
    PostHistoryInfo phi ON rp.PostId = phi.PostId
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;

-- Additional section for benchmarking NULL handling and corner cases
SELECT 
    COUNT(*) AS NullHandlingTests,
    SUM(CASE WHEN LastClosed IS NULL THEN 1 ELSE 0 END) AS TotalNullClosed,
    SUM(CASE WHEN LastReopened IS NULL THEN 1 ELSE 0 END) AS TotalNullReopened,
    COUNT(DISTINCT CASE WHEN LastClosed IS NOT NULL THEN PostId END) AS PostsClosed,
    COUNT(DISTINCT CASE WHEN LastReopened IS NOT NULL THEN PostId END) AS PostsReopened
FROM 
    (SELECT 
        COALESCE(p.PostId, ph.PostId) AS PostId,
        ph.LastClosed AS LastClosed,
        ph.LastReopened AS LastReopened
    FROM 
        PostHistoryInfo ph
    FULL OUTER JOIN 
        RankedPosts p ON p.PostId = ph.PostId) AS CombinedResults;
