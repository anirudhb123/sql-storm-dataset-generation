-- Performance Benchmarking Query

WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.Score
),
BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)

SELECT 
    u.DisplayName,
    uc.PostCount,
    uc.QuestionCount,
    uc.AnswerCount,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    SUM(pwv.VoteCount) AS TotalVoteCount,
    AVG(pwv.Score) AS AverageScore
FROM Users u
JOIN UserPostCounts uc ON u.Id = uc.UserId
LEFT JOIN BadgesCount bc ON u.Id = bc.UserId
LEFT JOIN PostsWithVotes pwv ON pwv.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = u.Id
)
GROUP BY u.Id, u.DisplayName, uc.PostCount, uc.QuestionCount, uc.AnswerCount, bc.BadgeCount
ORDER BY uc.PostCount DESC;
