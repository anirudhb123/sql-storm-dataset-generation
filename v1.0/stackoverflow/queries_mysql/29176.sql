
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS OwnerPostRank,
        @prev_owner := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := NULL) AS init
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.OwnerUserId, u.DisplayName
),
FilteredTags AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(p.ViewCount) AS TotalViews,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    CROSS JOIN (SELECT @user_rank := 0) AS init
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalViews DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    GROUP_CONCAT(DISTINCT ft.TagName ORDER BY ft.TagName SEPARATOR ', ') AS Tags,
    rp.CommentCount,
    rp.VoteCount,
    ur.DisplayName AS TopOwnerUser,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    ur.TotalViews,
    rp.OwnerPostRank
FROM 
    RankedPosts rp
JOIN 
    FilteredTags ft ON rp.Tags LIKE CONCAT('%', ft.TagName, '%')
JOIN 
    UserRankings ur ON rp.OwnerUserId = ur.UserId
WHERE 
    rp.OwnerPostRank = 1
GROUP BY 
    rp.PostId, rp.Title, rp.CommentCount, rp.VoteCount, ur.DisplayName, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges, ur.TotalViews, rp.OwnerPostRank
ORDER BY 
    rp.VoteCount DESC, rp.CommentCount DESC
LIMIT 50;
