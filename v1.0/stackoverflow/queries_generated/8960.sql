WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.LastActivityDate, 
           p.Score, 
           u.DisplayName AS OwnerDisplayName, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT v.Id) AS VoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.LastActivityDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
),
Statistics AS (
    SELECT PostTypeId, 
           COUNT(*) AS TotalPosts, 
           AVG(Score) AS AvgScore, 
           AVG(CommentCount) AS AvgComments,
           AVG(VoteCount) AS AvgVotes
    FROM RankedPosts
    GROUP BY PostTypeId
)
SELECT pt.Name AS PostType, 
       s.TotalPosts, 
       ROUND(s.AvgScore, 2) AS AverageScore, 
       ROUND(s.AvgComments, 2) AS AverageComments, 
       ROUND(s.AvgVotes, 2) AS AverageVotes
FROM Statistics s
JOIN PostTypes pt ON s.PostTypeId = pt.Id
ORDER BY TotalPosts DESC, AverageScore DESC;
