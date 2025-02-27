WITH RECURSIVE UserScoreRank AS (
    SELECT Id, Reputation, 
           RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostStats AS (
    SELECT p.Id AS PostId, 
           COUNT(c.Id) AS TotalComments, 
           AVG(COALESCE(v.VoteCount, 0)) AS AverageVotesPerComment
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(Id) AS VoteCount
        FROM Votes
        WHERE VoteTypeId = 2
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id
),
RecentPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate,
           p.Score,
           ps.TotalComments,
           ps.AverageVotesPerComment,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    JOIN PostStats ps ON p.Id = ps.PostId
    WHERE p.PostTypeId = 1  -- only questions
),
TopUsers AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           us.Rank
    FROM Users u
    JOIN UserScoreRank us ON u.Id = us.Id
    WHERE us.Rank <= 10
),
ClosedPosts AS (
    SELECT DISTINCT p.Id, 
           ph.UserId AS CloserId, 
           ph.CreationDate AS CloseDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT rp.Title, 
       rp.CreationDate AS PostCreationDate, 
       rp.TotalComments, 
       rp.AverageVotesPerComment,
       u.DisplayName AS OwnerName,
       u.Reputation AS OwnerReputation,
       tp.UserId AS TopUserId,
       cp.CloseDate AS PostCloseDate
FROM RecentPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN ClosedPosts cp ON rp.Id = cp.Id
LEFT JOIN TopUsers tp ON tp.UserId = u.Id
WHERE rp.UserPostRank <= 5
ORDER BY rp.TotalComments DESC, rp.AverageVotesPerComment DESC;
