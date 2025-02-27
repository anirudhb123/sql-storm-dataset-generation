WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (NOW() - INTERVAL '1 year')
    GROUP BY 
        p.Id
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS IsEdited,
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pha.LastEditDate,
    pha.IsEdited,
    pha.RevisionCount,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    CASE 
        WHEN rp.Score >= 0 AND ub.BadgeCount > 0 THEN 'Popular with Badges'
        WHEN rp.Score < 0 THEN 'Unpopular'
        ELSE 'Neutral'
    END AS PopularityTag
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreatedDate DESC
FETCH FIRST 50 ROWS ONLY;
