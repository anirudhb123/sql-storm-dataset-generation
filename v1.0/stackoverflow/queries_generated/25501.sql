WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        p.Score,
        p.ViewCount,
        p.Title
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName ON TRUE
    JOIN 
        Tags t ON t.TagName = TagName
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id, p.Score, p.ViewCount, p.Title
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        u.Reputation > 100 -- Only considering high-reputation users
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.DisplayName,
    p.Title,
    p.TagCount,
    u.QuestionCount,
    u.Upvotes,
    u.Downvotes,
    ROUND((p.Score::decimal / NULLIF(u.Upvotes + 1, 0)), 2) AS ScorePerUpvote,
    ROUND((p.ViewCount::decimal / NULLIF(u.QuestionCount + 1, 0)), 2) AS AvgViewsPerQuestion
FROM 
    PostTagCounts p
JOIN 
    UserActivity u ON p.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.UserId)
ORDER BY 
    ScorePerUpvote DESC, AvgViewsPerQuestion DESC
LIMIT 10;
