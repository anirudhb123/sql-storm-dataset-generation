WITH RankedUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
), 
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COALESCE(c.CommentCount, 0) AS TotalComments
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
), 
DetailedPostHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        p.Title, 
        p.Score,
        p.ViewCount,
        pt.Name AS PostTypeName,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '90 days'
)
SELECT 
    u.DisplayName AS UserName,
    COUNT(DISTINCT ps.PostId) AS PostCount,
    SUM(ps.TotalUpVotes - ps.TotalDownVotes) AS NetVoteScore,
    AVG(ps.TotalComments) AS AverageCommentsPerPost,
    MAX(dph.CreationDate) AS LastEditDate,
    STRING_AGG(DISTINCT dph.Comment, '; ') AS RecentEditsComments
FROM RankedUsers u
LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
LEFT JOIN DetailedPostHistory dph ON ps.PostId = dph.PostId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName
HAVING COUNT(DISTINCT ps.PostId) > 5
ORDER BY NetVoteScore DESC
LIMIT 10;
