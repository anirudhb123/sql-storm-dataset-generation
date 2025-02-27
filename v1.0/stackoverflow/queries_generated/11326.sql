-- Performance Benchmarking Query
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    *,
    CASE 
        WHEN PostCount > 0 THEN 
            (Upvotes - Downvotes) / PostCount 
        ELSE 0 
    END AS VoteRatio,
    QuestionCount::float / NULLIF(PostCount, 0) AS QuestionRatio,
    AnswerCount::float / NULLIF(PostCount, 0) AS AnswerRatio,
    WikiCount::float / NULLIF(PostCount, 0) AS WikiRatio
FROM 
    UserReputation
ORDER BY 
    Reputation DESC, PostCount DESC
LIMIT 100;
