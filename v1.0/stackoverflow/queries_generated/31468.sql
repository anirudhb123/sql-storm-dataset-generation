WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        CreationDate,
        DisplayName,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000

    UNION ALL 

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON u.Reputation > (ur.Reputation - 500)
    WHERE ur.Level < 5
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
),
FilteredPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title, 
        ps.Upvotes - ps.Downvotes AS NetScore,
        ps.TotalVotes,
        ROW_NUMBER() OVER (ORDER BY ps.Upvotes DESC) AS Ranking
    FROM PostVoteSummary ps
    WHERE ps.TotalVotes > 10
)

SELECT 
    u.DisplayName,
    u.Reputation,
    r.UserId,
    r.Level AS ReputationLevel,
    f.PostId,
    f.Title,
    f.NetScore,
    f.Ranking
FROM UserReputation r
LEFT JOIN Users u ON r.UserId = u.Id
INNER JOIN FilteredPosts f ON f.Ranking <= 10
WHERE COALESCE(u.Location, 'Unknown') LIKE '%USA%'
ORDER BY r.Level DESC, f.NetScore DESC;
