
WITH UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (SELECT 1 FROM Comments c WHERE c.PostId = p.Id LIMIT 1) IS NOT NULL AS HasComments,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.UpVoteCount,
    u.DownVoteCount,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.HasComments
FROM 
    UserStats u
JOIN 
    PostStats p ON u.Id = p.OwnerUserId
ORDER BY 
    u.Reputation DESC, 
    p.Score DESC;
