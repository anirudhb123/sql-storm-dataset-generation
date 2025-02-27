WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
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
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    (CASE 
        WHEN rp.RankByScore IS NULL THEN 'No Posts'
        WHEN rp.RankByScore > 10 THEN 'Low Performer'
        ELSE 'High Performer' 
    END) AS PerformanceRanking
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.RankByScore = 1 AND rp.OwnerUserId = us.UserId
WHERE 
    rp.CommentCount > 0
ORDER BY 
    rp.Score DESC, us.BadgeCount DESC
LIMIT 50;

WITH PotentialDuplicatePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id AND pl.LinkTypeId = 3) AS DuplicateLinkCount
    FROM 
        Posts p
)
SELECT 
    pdp.PostId,
    pdp.Title,
    COALESCE(pd.DuplicateLinkCount, 0) AS DuplicateLinkCount
FROM 
    PotentialDuplicatePosts pdp
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS DuplicateLinkCount 
     FROM 
         PostLinks 
     WHERE 
         LinkTypeId = 3 
     GROUP BY 
         PostId) pd ON pdp.PostId = pd.PostId
WHERE 
    pdp.DuplicateLinkCount > 0
ORDER BY 
    pdp.Title;
