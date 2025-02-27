WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart or BountyClose
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.ViewCount,
        rp.RankByScore,
        rp.CommentCount,
        rp.TotalBounty,
        CASE 
            WHEN rp.RankByScore <= 5 THEN 'Top Posts'
            ELSE 'Regular Posts'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0 
        AND rp.TotalBounty > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    u.DisplayName AS OwnerDisplayName,
    fp.ViewCount,
    fp.CommentCount,
    fp.TotalBounty,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    CASE 
        WHEN u.Reputation >= 1000 THEN 'Experienced User'
        ELSE 'New User'
    END AS UserExperience,
    CASE 
        WHEN bp.PostId IS NULL THEN 'Post without links'
        ELSE 'Related Post Found'
    END AS LinkStatus
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    PostLinks bp ON fp.PostId = bp.PostId
WHERE 
    fp.PostCategory = 'Top Posts'
ORDER BY 
    fp.TotalBounty DESC, 
    fp.ViewCount DESC
LIMIT 100;
