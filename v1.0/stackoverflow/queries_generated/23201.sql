WITH RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS ActivityRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COALESCE(SUM(v.VoteTypeId = 2) FILTER (WHERE v.CreationDate >= NOW() - INTERVAL '6 MONTH'), 0) AS RecentUpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) FILTER (WHERE v.CreationDate >= NOW() - INTERVAL '6 MONTH'), 0) AS RecentDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostLinksData AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount,
        MAX(pl.CreationDate) AS LastLinkDate
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
CombinedData AS (
    SELECT 
        ra.PostId,
        ra.Title,
        us.DisplayName AS OwnerDisplayName,
        us.Reputation AS OwnerReputation,
        pl.RelatedPostsCount,
        pl.LastLinkDate
    FROM 
        RecentActivity ra
    JOIN 
        UserStats us ON us.UserId = ra.OwnerUserId
    LEFT JOIN 
        PostLinksData pl ON pl.PostId = ra.PostId
    WHERE 
        ra.ActivityRank = 1
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.OwnerDisplayName,
    cd.OwnerReputation,
    COALESCE(cd.RelatedPostsCount, 0) AS RelatedCount,
    CASE WHEN cd.LastLinkDate IS NULL THEN 'No links' ELSE 'Links available' END AS LinkStatus
FROM 
    CombinedData cd
ORDER BY 
    cd.OwnerReputation DESC,
    cd.LastLinkDate DESC NULLS LAST;
