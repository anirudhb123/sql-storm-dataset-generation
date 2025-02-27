WITH RankedUserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 10 THEN 1 END) AS Deletions,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM Votes v
    JOIN Posts p ON v.PostId = p.Id
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY v.UserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS ActivePosts
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.LastAccessDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY u.Id
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.ActivePosts,
    rv.UpVotes,
    rv.DownVotes,
    rv.Deletions,
    rv.VoteRank
FROM ActiveUsers au
LEFT JOIN RankedUserVotes rv ON au.Id = rv.UserId
WHERE au.Reputation > 1000
ORDER BY rv.VoteRank, au.DisplayName
OPTION (MAXRECURSION 0);
