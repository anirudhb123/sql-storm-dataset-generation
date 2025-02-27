
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(TIMESTAMPDIFF(SECOND, u.CreationDate, '2024-10-01 12:34:56') / 86400) AS AccountAgeInDays
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVotes,
    us.DownVotes,
    us.AccountAgeInDays,
    (@row_number := @row_number + 1) AS Rank
FROM 
    UserStatistics us,
    (SELECT @row_number := 0) AS r
WHERE 
    us.PostCount > 5
ORDER BY 
    us.Reputation DESC, us.PostCount DESC;
