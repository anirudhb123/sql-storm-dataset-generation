WITH RecursivePosts AS (
    -- CTE to recursively retrieve all parent posts for answers
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Base case: Questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        pp.Title,
        pp.CreationDate,
        rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
    WHERE p.PostTypeId = 2  -- Recursive case: Answers
),
AggregatedData AS (
    -- Aggregate important metrics for questions
    SELECT 
        rp.Id AS QuestionId,
        rp.Title,
        COUNT(a.Id) AS AnswerCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        COUNT(CASE WHEN a.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswersCount,
        MAX(rp.CreationDate) AS LatestActivity
    FROM RecursivePosts rp
    LEFT JOIN Posts a ON rp.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON a.Id = v.PostId
    WHERE rp.Level = 0 -- Only take questions
    GROUP BY rp.Id, rp.Title
),
UserBadges AS (
    -- CTE to summarize user badges and their reputations
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
TopUsersQuestions AS (
    -- CTE to find top users by reputation who have asked the most answered questions
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT q.Id) AS QuestionCount,
        SUM(ag.TotalVotes) AS TotalVotes,
        SUM(ag.AcceptedAnswersCount) AS TotalAcceptedAnswers
    FROM Users u
    JOIN Posts q ON u.Id = q.OwnerUserId AND q.PostTypeId = 1
    LEFT JOIN AggregatedData ag ON q.Id = ag.QuestionId 
    WHERE q.AnswerCount > 0
    GROUP BY u.Id, u.DisplayName
    ORDER BY TotalVotes DESC
    LIMIT 10
)
-- Final selection pulling together metrics, user data, and post details
SELECT 
    t.UserId,
    t.DisplayName,
    t.QuestionCount,
    t.TotalVotes,
    t.TotalAcceptedAnswers,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    b.Reputation,
    a.Title,
    a.AnswerCount,
    a.LatestActivity
FROM TopUsersQuestions t
LEFT JOIN UserBadges b ON t.UserId = b.UserId
LEFT JOIN AggregatedData a ON a.QuestionId IN (SELECT q.Id FROM Posts q WHERE q.OwnerUserId = t.UserId AND q.PostTypeId = 1)
ORDER BY t.TotalVotes DESC;
