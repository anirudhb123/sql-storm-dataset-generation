WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank,
           COUNT(*) OVER () AS TotalUsers
    FROM Users
),
TopUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM UserReputation
    WHERE Rank <= 10
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS TotalPosts, SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostDetails AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, ps.TotalPosts, ps.TotalQuestions, ps.TotalAnswers, ps.TotalViews,
           ROUND((ps.TotalViews::DECIMAL / NULLIF(ps.TotalPosts, 0)), 2) AS AvgViewsPerPost
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
),
RecentVotes AS (
    SELECT v.PostId, COUNT(v.Id) AS TotalVotes
    FROM Votes v
    WHERE v.CreationDate > (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY v.PostId
)
SELECT u.DisplayName, u.Reputation, COALESCE(upd.TotalPosts, 0) AS TotalPosts, 
       COALESCE(upd.TotalQuestions, 0) AS TotalQuestions, COALESCE(upd.TotalAnswers, 0) AS TotalAnswers,
       COALESCE(upd.TotalViews, 0) AS TotalViews, 
       nv.TotalVotes, 
       CASE 
           WHEN nv.TotalVotes IS NOT NULL THEN 'Active'
           ELSE 'Inactive'
       END AS VotingStatus,
       (SELECT STRING_AGG(tag.TagName, ', ') 
        FROM Tags tag 
        WHERE tag.Id IN (SELECT DISTINCT UNNEST(string_to_array(p.Tags, '><'))::int[] FROM Posts p WHERE p.OwnerUserId = u.Id)) AS TagsUsed
FROM UserPostDetails upd
JOIN TopUsers u ON upd.UserId = u.Id
LEFT JOIN RecentVotes nv ON nv.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
ORDER BY u.Reputation DESC;
