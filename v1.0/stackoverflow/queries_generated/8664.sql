WITH RankedUsers AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId IN (10, 11)) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
), 
ModeratedPosts AS (
    SELECT 
        p.Title,
        ps.Score,
        ps.ViewCount,
        ru.DisplayName AS ModeratorName,
        ru.Reputation AS ModeratorReputation
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN RankedUsers ru ON ph.UserId = ru.UserId
    JOIN PostStatistics ps ON p.Id = ps.PostId
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Only consider posts that were closed or reopened
)
SELECT 
    mp.Title,
    mp.Score,
    mp.ViewCount,
    mp.ModeratorName,
    mp.ModeratorReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM ModeratedPosts mp
LEFT JOIN Comments c ON mp.Title = c.Text
LEFT JOIN Votes v ON mp.Title = v.PostId
GROUP BY mp.Title, mp.Score, mp.ViewCount, mp.ModeratorName, mp.ModeratorReputation
ORDER BY mp.Score DESC, mp.ViewCount DESC
LIMIT 10;
