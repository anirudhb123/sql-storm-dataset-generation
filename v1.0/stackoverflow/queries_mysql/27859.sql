
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagNames
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) tag
         FROM (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
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
        CommentCount > 5 AND AnswerCount >= 3  
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
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
    UserEngagement ue ON ue.TotalVotes > 10  
ORDER BY 
    hsp.CommentCount DESC, 
    hsp.AnswerCount DESC;
