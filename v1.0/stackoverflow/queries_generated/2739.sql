WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PopularPosts AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(*) AS PostCount,
        SUM(rp.Score) AS TotalScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
    GROUP BY 
        rp.OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    pp.OwnerDisplayName,
    pp.PostCount,
    pp.TotalScore,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM 
    PopularPosts pp
LEFT JOIN 
    UserBadges ub ON pp.OwnerDisplayName = ub.DisplayName
WHERE 
    pp.TotalScore > (SELECT AVG(TotalScore) FROM PopularPosts)
ORDER BY 
    pp.TotalScore DESC
LIMIT 10;

-- Investigating the effect of votes on posts with multiple comments
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title
HAVING 
    COUNT(c.Id) > 5 AND SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 0
ORDER BY 
    p.Score DESC;
