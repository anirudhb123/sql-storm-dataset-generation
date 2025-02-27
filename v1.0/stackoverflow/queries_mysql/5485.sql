
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(vs.VoteCount, 0)) AS VoteCount,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) vs ON p.Id = vs.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RankedUsers AS (
    SELECT 
        us.*,
        @rank := IF(@prevReputation = us.Reputation AND @prevPostCount = us.PostCount, @rank, @rank + 1) AS ReputationRank,
        @prevReputation := us.Reputation,
        @prevPostCount := us.PostCount
    FROM 
        UserStats us, (SELECT @rank := 0, @prevReputation := NULL, @prevPostCount := NULL) r
    ORDER BY 
        us.Reputation DESC, us.PostCount DESC
)
SELECT 
    ru.UserId, 
    ru.DisplayName, 
    ru.Reputation, 
    ru.CreationDate, 
    ru.PostCount, 
    ru.QuestionCount, 
    ru.AnswerCount, 
    ru.VoteCount, 
    ru.BadgeCount, 
    (SELECT COUNT(*) FROM Users) AS TotalUsers
FROM 
    RankedUsers ru
WHERE 
    ru.ReputationRank <= 10
ORDER BY 
    ru.Reputation DESC;
