WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag,
        p.Id AS PostId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
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
    rp.OwnerName,
    rp.CommentCount,
    rp.VoteCount,
    tb.Tag AS MostUsedTag,
    ua.DisplayName AS TopUser,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT Tag, COUNT(*) AS TagCount
     FROM TagUsage
     GROUP BY Tag
     ORDER BY TagCount DESC
     LIMIT 1) tb ON true
JOIN 
    (SELECT UserId, DisplayName, 
            RANK() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC) AS UserRank
     FROM UserActivity) ua ON ua.UserRank = 1 
WHERE 
    rp.PostRank <= 5; -- Get top 5 posts of each type
