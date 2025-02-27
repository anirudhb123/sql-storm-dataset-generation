WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000 -- Filter for users with a reputation greater than 1000
    GROUP BY 
        u.Id, u.Reputation
),
QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COALESCE(SUM(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ur.UserId,
    ur.Reputation,
    ur.TotalPosts,
    ur.TotalQuestions,
    ur.TotalAnswers,
    qs.QuestionId,
    qs.Title AS QuestionTitle,
    qs.Upvotes,
    qs.Downvotes,
    qs.CommentCount
FROM 
    TagStats ts
JOIN 
    UserReputation ur ON ur.TotalQuestions > 0 -- Only users who asked questions
JOIN 
    QuestionStats qs ON ts.QuestionCount > 0 -- Only tags associated with questions
ORDER BY 
    ts.PostCount DESC, ur.Reputation DESC
LIMIT 100;
