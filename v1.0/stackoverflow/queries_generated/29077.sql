WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
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
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Author,
        ut.UserId,
        ut.DisplayName AS UserName,
        ut.BadgeCount,
        ut.GoldBadges,
        ut.SilverBadges,
        ut.BronzeBadges,
        pt.TagName
    FROM 
        RankedPosts rp
    JOIN 
        UserBadgeStats ut ON rp.PostRank = 1 AND rp.Author = ut.DisplayName 
    JOIN 
        PopularTags pt ON pt.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Body,
    fr.CreationDate,
    fr.ViewCount,
    fr.AnswerCount,
    fr.CommentCount,
    fr.Author,
    fr.UserId,
    fr.UserName,
    fr.BadgeCount,
    fr.GoldBadges,
    fr.SilverBadges,
    fr.BronzeBadges,
    fr.TagName
FROM 
    FinalResults fr
ORDER BY 
    fr.ViewCount DESC, fr.CreationDate DESC;
