WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.OwnerUserId
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CommentCount,
    rp.CreationDate,
    rp.Score,
    ut.DisplayName AS OwnerDisplayName,
    ut.TotalUpVotes,
    ut.TotalDownVotes,
    ut.GoldBadges,
    ut.SilverBadges,
    ut.BronzeBadges,
    pt.Tag AS PopularTag,
    pt.TagCount
FROM 
    RankedPosts rp
JOIN 
    UserStats ut ON rp.OwnerUserId = ut.UserId
JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(SUBSTRING(rp.Tags FROM 2 FOR LENGTH(rp.Tags) - 2), '><'))
WHERE 
    rp.UserPostRank <= 5 
ORDER BY 
    rp.Score DESC, rp.CommentCount DESC;

