WITH TagUsage AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(badge.BadgeCount, 0) AS OwnerBadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        UserReputation badge ON u.Id = badge.UserId
)
SELECT 
    tu.TagName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerName,
    ps.CommentCount,
    ps.OwnerBadgeCount
FROM 
    TagUsage tu
JOIN 
    PostStatistics ps ON ps.Title ILIKE '%' || tu.TagName || '%'
WHERE 
    tu.PostCount > 10
ORDER BY 
    tu.PostCount DESC, 
    ps.CreationDate DESC
LIMIT 50;
