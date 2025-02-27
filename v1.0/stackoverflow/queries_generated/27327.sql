WITH TagCount AS (
    SELECT 
        post.Id AS PostId,
        COUNT(DISTINCT REGEXP_SPLIT_TO_TABLE(substring(post.Tags, 2, length(post.Tags) - 2), '><')) AS TagNum
    FROM 
        Posts post
    WHERE 
        post.PostTypeId = 1 -- Only count tags for questions
    GROUP BY 
        post.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Count for Questions and Answers
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pa.CommentCount,
    pa.VoteCount,
    tc.TagNum,
    pa.LastActivity
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
JOIN 
    PostActivity pa ON pa.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN 
    TagCount tc ON tc.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
WHERE 
    us.PostCount > 0
ORDER BY 
    LastActivity DESC, 
    PostCount DESC;
