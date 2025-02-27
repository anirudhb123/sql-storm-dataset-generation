WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount,
        AVG(u.Reputation) AS AverageReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(c.CommentCount) AS TotalComments,
        AVG(p.ViewCount) AS AverageViewCount
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(STRING_TO_ARRAY(p.Tags, ',')::int[]) 
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY t.Id
)
SELECT 
    us.DisplayName,
    us.QuestionCount,
    us.AcceptedAnswerCount,
    us.UpVotesCount,
    us.DownVotesCount,
    us.AverageReputation,
    ts.TagName,
    ts.PostCount,
    ts.TotalComments,
    ts.AverageViewCount
FROM UserStats us
JOIN TagStats ts ON us.QuestionCount > 0 AND ts.PostCount > 0
WHERE us.AverageReputation > 100
ORDER BY us.QuestionCount DESC, ts.PostCount DESC
LIMIT 50;
