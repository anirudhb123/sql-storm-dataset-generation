WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Name = 'Wiki' THEN 1 ELSE 0 END) AS WikiCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),

TopContent AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount 
               FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
)

SELECT 
    u.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.WikiCount,
    us.AvgScore,
    us.Upvotes,
    us.Downvotes,
    tc.PostId,
    tc.Title,
    tc.Tags,
    tc.ViewCount,
    tc.CreationDate
FROM UserPostStats us
JOIN TopContent tc ON us.UserId = tc.OwnerName
ORDER BY us.PostCount DESC, tc.ViewCount DESC
LIMIT 100;
