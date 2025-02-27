WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
RecentActivity AS (
    SELECT 
        ua.UserId,
        COUNT(c.Id) AS CommentCount,
        AVG(EXTRACT(EPOCH FROM (NOW() - p.CreationDate))/3600) AS AvgPostAgeInHours
    FROM Users ua
    LEFT JOIN Comments c ON ua.Id = c.UserId
    LEFT JOIN Posts p ON ua.Id = p.OwnerUserId
    GROUP BY ua.UserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        ra.CommentCount,
        ra.AvgPostAgeInHours,
        (us.UpVotesCount - us.DownVotesCount) AS NetVoteScore
    FROM UserStats us
    LEFT JOIN RecentActivity ra ON us.UserId = ra.UserId
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Reputation,
    cs.PostCount,
    cs.CommentCount,
    cs.AvgPostAgeInHours,
    cs.NetVoteScore,
    CASE 
        WHEN cs.Reputation >= 1000 THEN 'High Reputation User'
        WHEN cs.Reputation BETWEEN 500 AND 999 THEN 'Moderate Reputation User'
        ELSE 'New User'
    END AS UserCategory
FROM CombinedStats cs
WHERE cs.PostCount > 0
  AND cs.AvgPostAgeInHours < 24
ORDER BY cs.NetVoteScore DESC, cs.Reputation DESC
LIMIT 10;

-- This query retrieves a list of users based on their activity and reputation,
-- categorizing them while considering only users who have actively contributed posts
-- in the past 24 hours and have a net positive vote score. The result is sorted to
-- highlight the most impactful users for further analysis.
