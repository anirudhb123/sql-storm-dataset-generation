WITH UserStats AS (
    SELECT u.Id AS UserId, 
           u.Reputation, 
           u.CreationDate, 
           u.LastAccessDate, 
           COUNT(DISTINCT p.Id) AS PostCount, 
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(COALESCE(vs.VoteCount, 0)) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) vs ON p.Id = vs.PostId
    GROUP BY u.Id, u.Reputation, u.CreationDate, u.LastAccessDate
),
PopularTags AS (
    SELECT t.TagName, 
           COUNT(p.Id) AS PostCount 
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 10
    ORDER BY PostCount DESC
    LIMIT 5
),
RecentActivity AS (
    SELECT u.DisplayName, 
           p.Title, 
           p.CreationDate, 
           p.ViewCount,
           (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT us.UserId, 
       us.Reputation, 
       us.PostCount, 
       us.QuestionCount, 
       us.AnswerCount, 
       us.TotalVotes, 
       pt.TagName, 
       ra.DisplayName, 
       ra.Title, 
       ra.CreationDate, 
       ra.ViewCount, 
       ra.CommentCount
FROM UserStats us
CROSS JOIN PopularTags pt
JOIN RecentActivity ra ON us.UserId = ra.UserId
ORDER BY us.Reputation DESC, ra.ViewCount DESC;
