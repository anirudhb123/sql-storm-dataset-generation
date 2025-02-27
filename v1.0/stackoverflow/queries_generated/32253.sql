WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2022-01-01'
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Tags, p.OwnerUserId
),
TagPopularity AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
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
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.Score,
        tp.Tag,
        tp.UsageCount,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TagPopularity tp ON tp.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.UserRank <= 5
)
SELECT 
    PostId,
    Title,
    CommentCount,
    Score,
    COALESCE(SUM(UsageCount), 0) AS TotalTagUsage,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    FinalResults
GROUP BY 
    PostId, Title, CommentCount, Score, BadgeCount, GoldBadges, SilverBadges, BronzeBadges
ORDER BY 
    Score DESC, CommentCount DESC
LIMIT 100;
