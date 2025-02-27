WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgeCount,
        SUM(COALESCE(b.TagBased, 0)) AS TotalTagBasedBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.UpvoteCount,
    u.DisplayName AS AuthorDisplayName,
    COALESCE(u.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(u.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(u.BronzeBadgeCount, 0) AS BronzeBadges,
    u.TotalTagBasedBadges,
    CASE 
        WHEN p.UserPostRank = 1 THEN 'Most Recent Post'
        ELSE NULL
    END AS PostStatus
FROM 
    RankedPosts p
LEFT JOIN 
    UsersWithBadges u ON p.PostId = u.UserId
WHERE 
    p.CommentCount > 5
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 50;
