WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount,
        MIN(pl.CreationDate) AS FirstLinkedDate,
        MAX(pl.CreationDate) AS LastLinkedDate
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COALESCE(rp.RankScore, 0) AS RankScore,
    COALESCE(d.BadgeCount, 0) AS TotalBadges,
    COALESCE(d.BadgeNames, 'None') AS UserBadges,
    pl.RelatedPostsCount,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(pc.LastActivityDate, '1970-01-01') AS LastActivityDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.PostId
LEFT JOIN 
    UserBadges d ON u.Id = d.UserId
LEFT JOIN 
    PostLinksSummary pl ON p.Id = pl.PostId
LEFT JOIN 
    (SELECT DISTINCT PostId, LastActivityDate 
     FROM Posts 
     WHERE LastActivityDate IS NOT NULL) pc ON p.Id = pc.PostId
WHERE 
    u.Reputation > (
        SELECT AVG(Reputation) 
        FROM Users 
        WHERE LastAccessDate < NOW() - INTERVAL '30 days'
    )
ORDER BY 
    u.Reputation DESC, p.ViewCount DESC, RankScore DESC
FETCH FIRST 100 ROWS ONLY;
