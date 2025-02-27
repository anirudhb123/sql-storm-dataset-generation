WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT 
    u.DisplayName,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.TotalViews,
    u.TotalScore,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.UserId AND Score > 0) AS PositivePostCount
FROM 
    TopUsers u
WHERE 
    (u.GoldBadges + u.SilverBadges + u.BronzeBadges) > 0
ORDER BY 
    u.TotalScore DESC
FETCH FIRST 10 ROWS ONLY;

WITH RECURSIVE RelatedPosts AS (
    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        1 AS Depth
    FROM 
        PostLinks pl
    UNION ALL
    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        rp.Depth + 1
    FROM 
        PostLinks pl
    JOIN 
        RelatedPosts rp ON pl.PostId = rp.RelatedPostId
    WHERE 
        rp.Depth < 3
)
SELECT 
    p.Title,
    rp.RelatedPostId,
    COUNT(rp.RelatedPostId) OVER (PARTITION BY p.Id) AS RelationCount
FROM 
    Posts p
JOIN 
    RelatedPosts rp ON p.Id = rp.PostId
WHERE 
    rp.Depth = 2
ORDER BY 
    RelationCount DESC;
