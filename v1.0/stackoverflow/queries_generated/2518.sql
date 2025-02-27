WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1
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
),
AggregateVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rb.UserId,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    av.UpVotes,
    av.DownVotes,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Top Post'
        ELSE NULL 
    END AS RankStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users rb ON rp.OwnerUserId = rb.Id
LEFT JOIN 
    UserBadges ub ON rb.Id = ub.UserId
LEFT JOIN 
    AggregateVotes av ON rp.PostId = av.PostId
WHERE 
    ub.BadgeCount > 0
ORDER BY 
    rp.Score DESC NULLS LAST;
