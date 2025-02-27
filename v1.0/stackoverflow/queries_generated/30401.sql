WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation > 1000
    
    UNION ALL
    
    SELECT u.Id, u.Reputation
    FROM Users u
    INNER JOIN UserReputation ur ON ur.Reputation < u.Reputation
    WHERE u.Reputation > 1000
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ah.AvgScore, 0) AS AvgAnswerScore
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS UpVotes, COUNT(*) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, AVG(Score) AS AvgScore
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) ah ON p.Id = ah.ParentId
    WHERE p.CreationDate >= '2022-01-01'
    AND p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(ps.ViewCount) AS PostsViewed
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT OwnerUserId, SUM(ViewCount) AS ViewCount
        FROM Posts
        GROUP BY OwnerUserId
    ) ps ON u.Id = ps.OwnerUserId
    WHERE u.Reputation > 5000
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(b.Class) > 5
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalBadges,
    tu.PostsViewed,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    CASE 
        WHEN ps.Score > 10 THEN 'High Score'
        WHEN ps.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM TopUsers tu
JOIN PostStats ps ON tu.UserId = ps.OwnerUserId
ORDER BY tu.TotalBadges DESC, ps.Score DESC;
