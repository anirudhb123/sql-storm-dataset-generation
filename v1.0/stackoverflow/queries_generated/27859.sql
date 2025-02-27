WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagNames
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  -- Answers
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id
),

HighScoringPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        TagNames,
        CommentCount,
        AnswerCount
    FROM 
        TaggedPosts
    WHERE 
        CommentCount > 5 AND AnswerCount >= 3  -- Filter for engaging posts
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.CreationDate IS NOT NULL) AS TotalVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Body,
    hsp.TagNames,
    ue.DisplayName AS EngagingUser,
    ue.TotalVotes,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges
FROM 
    HighScoringPosts hsp
JOIN 
    UserEngagement ue ON ue.TotalVotes > 10  -- Filter users with significant engagement
ORDER BY 
    hsp.CommentCount DESC, 
    hsp.AnswerCount DESC;
