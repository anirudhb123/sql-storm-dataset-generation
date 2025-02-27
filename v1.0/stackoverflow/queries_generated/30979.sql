WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, CAST(DisplayName AS VARCHAR(1000)) AS FullPath
    FROM Users 
    WHERE Reputation > 1000  -- Starting point: Users with high reputation
    UNION ALL
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, 
           CONCAT(uh.FullPath, ' -> ', u.DisplayName)
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.Id -- Implement your own hierarchical logic here
),
RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, 
           RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' 
     AND p.ViewCount > 100 -- Considering popular posts
),
PostDetails AS (
    SELECT p.Id AS PostId,
           p.Title,
           P.OwnerDisplayName,
           p.CreationDate,
           COALESCE(c.CommentCount, 0) AS TotalComments,
           COALESCE(v.VoteCount, 0) AS TotalVotes,
           u.Reputation AS OwnerReputation,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Only Questions
),
TopUserPosts AS (
    SELECT ph.UserDisplayName, ph.FullPath, pp.Title, pp.TotalComments, pp.TotalVotes, pp.UserPostRank
    FROM PostDetails pp
    JOIN UserHierarchy ph ON pp.OwnerDisplayName = ph.DisplayName
    WHERE pp.UserPostRank <= 5 -- Shows only top 5 posts per user
)
SELECT 
    tp.UserDisplayName,
    tp.FullPath,
    COUNT(tp.Title) AS TotalPosts,
    SUM(tp.TotalComments) AS TotalComments,
    SUM(tp.TotalVotes) AS TotalVotes
FROM TopUserPosts tp
GROUP BY tp.UserDisplayName, tp.FullPath
HAVING SUM(tp.TotalVotes) > 10 -- Consider only users with substantial votes
ORDER BY TotalPosts DESC, TotalVotes DESC;
