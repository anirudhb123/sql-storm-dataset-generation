WITH UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(DISTINCT p.Id) AS TotalPosts, 
           COUNT(DISTINCT c.Id) AS TotalComments, 
           COUNT(DISTINCT b.Id) AS TotalBadges,
           SUM(COALESCE(vs.Score, 0)) AS TotalVotes, 
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
           RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank,
           RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes vs ON p.Id = vs.PostId AND vs.VoteTypeId IN (2, 3)
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT UserId, DisplayName, TotalPosts, TotalComments, TotalBadges, TotalVotes, TotalViews,
           ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS OverallRank
    FROM UserActivity
    WHERE TotalPosts > 0
)
SELECT t.UserId, 
       t.DisplayName, 
       t.TotalPosts, 
       t.TotalComments, 
       t.TotalBadges, 
       t.TotalVotes, 
       t.TotalViews, 
       t.OverallRank
FROM TopUsers t
WHERE t.OverallRank <= 10
ORDER BY t.OverallRank;
