WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS UpVoteCount,
           SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId
),
UserStats AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, 
           SUM(rp.Score) AS TotalScore, 
           COUNT(DISTINCT rp.Id) AS TotalPosts,
           SUM(rp.AnswerCount) AS TotalAnswers,
           SUM(rp.CommentCount) AS TotalComments,
           SUM(rp.UpVoteCount) AS TotalUpVotes,
           SUM(rp.DownVoteCount) AS TotalDownVotes
    FROM Users u
    JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, TotalScore, TotalPosts, TotalAnswers, TotalComments,
           TotalUpVotes, TotalDownVotes,
           RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM UserStats
)
SELECT *,
       CASE 
           WHEN UserRank <= 10 THEN 'Top Contributor'
           WHEN TotalPosts >= 50 THEN 'Frequent Poster'
           ELSE 'Regular User'
       END AS UserCategory
FROM TopUsers
ORDER BY UserRank;
