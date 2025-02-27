WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, 0 AS Level
    FROM Users
    WHERE Reputation > 1000  -- Start with "high-reputation" users

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate, uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Reputation < uh.Reputation  -- Lower reputation users
    WHERE uh.Level < 5  -- Limit the hierarchy level for performance
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(Answers.AnswerCount, 0) AS AnswerCount,
        COALESCE(Votes.TotalVotes, 0) AS TotalVotes
    FROM Posts p
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2  -- Answers
        GROUP BY ParentId
    ) Answers ON p.Id = Answers.ParentId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS TotalVotes
        FROM Votes
        GROUP BY PostId
    ) Votes ON p.Id = Votes.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'  -- Recent posts
),
RankedPosts AS (
    SELECT 
        ps.Id,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.AnswerCount,
        ps.TotalVotes,
        RANK() OVER (PARTITION BY ps.AnswerCount ORDER BY ps.Score DESC) AS RankByScore
    FROM PostStats ps
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.TotalVotes,
    CASE 
        WHEN rp.TotalVotes > 100 THEN 'Highly Voted'
        WHEN rp.TotalVotes BETWEEN 50 AND 100 THEN 'Moderately Voted'
        ELSE 'Low Voted'
    END AS VoteCategory,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM UserHierarchy u
JOIN RankedPosts rp ON u.Id = rp.Id  -- Assuming user is the owner of posts
LEFT JOIN Comments c ON c.PostId = rp.Id
WHERE rp.RankByScore = 1  -- Top-ranked posts for each answer count
GROUP BY u.Id, rp.Title, rp.CreationDate, rp.Score, rp.AnswerCount, rp.TotalVotes
ORDER BY u.Reputation DESC, rp.Score DESC
LIMIT 50;  -- Limit the number of results for performance
