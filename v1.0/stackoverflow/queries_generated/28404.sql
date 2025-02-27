WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  -- Considering only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount
),
TopTagPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5  -- Top 5 most viewed posts per tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.AnswerCount,
    t.Tags,
    ue.DisplayName AS Author,
    ue.VoteCount,
    ue.CommentCount,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges
FROM 
    TopTagPosts t
JOIN 
    Posts p ON p.Id = t.PostId
JOIN 
    Users u ON u.Id = p.OwnerUserId
JOIN 
    UserEngagement ue ON ue.UserId = u.Id
ORDER BY 
    t.ViewCount DESC, ue.VoteCount DESC;
