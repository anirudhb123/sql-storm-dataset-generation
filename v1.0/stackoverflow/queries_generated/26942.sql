WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Filtering for questions only
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore
    FROM 
        TopPosts
    GROUP BY 
        TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges, 
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AvgViewCount,
    ts.TotalScore,
    ub.UserId,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    TagStatistics ts
JOIN 
    Users u ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id AND p.Tags LIKE '%' || ts.TagName || '%'
    )
JOIN 
    UserBadges ub ON ub.UserId = u.Id
ORDER BY 
    ts.PostCount DESC, 
    ts.TotalScore DESC;
