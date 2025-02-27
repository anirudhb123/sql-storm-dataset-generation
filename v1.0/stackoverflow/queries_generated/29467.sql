WITH TagCounts AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags tag
    LEFT JOIN 
        Posts p ON tag.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        tag.TagName
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
)

SELECT 
    tc.TagName,
    tc.PostCount,
    tc.QuestionCount,
    tc.AnswerCount,
    ur.DisplayName AS TopUser,
    ur.Reputation,
    ur.BadgeCount,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount
FROM 
    TagCounts tc
JOIN 
    (
        SELECT 
            DISTINCT ON (p.Id) p.Id AS PostId, u.Id AS UserId,
            u.DisplayName, u.Reputation, u.BadgeCount
        FROM 
            Posts p
        JOIN 
            UserReputation u ON p.OwnerUserId = u.UserId
        ORDER BY 
            p.Id, u.Reputation DESC
    ) ur ON ur.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || tc.TagName || '%')
JOIN 
    PostStats ps ON ps.PostId = ur.PostId
WHERE 
    tc.PostCount > 0
ORDER BY 
    tc.TagName, ur.Reputation DESC;
