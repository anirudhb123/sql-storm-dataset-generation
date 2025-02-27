WITH RECURSIVE UserHierarchy AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        CreationDate,
        LastAccessDate,
        Location,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000
    UNION ALL
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Location,
        uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Reputation > uh.Reputation AND u.Id <> uh.Id
),
PostScore AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        CASE 
            WHEN vt.Name = 'UpMod' THEN SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END)
            WHEN vt.Name = 'DownMod' THEN SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)
            ELSE 0
        END AS PositiveVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY v.PostId, v.UserId
),
AggregatedVotes AS (
    SELECT 
        rv.UserId,
        COUNT(rv.VoteCount) AS TotalRecentVotes,
        SUM(rv.PositiveVotes) AS TotalPositiveVotes
    FROM RecentVotes rv
    GROUP BY rv.UserId
),
FinalMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        uh.Level,
        us.TotalScore,
        av.TotalRecentVotes,
        av.TotalPositiveVotes
    FROM Users u
    LEFT JOIN UserHierarchy uh ON u.Id = uh.Id
    LEFT JOIN PostScore us ON u.Id = us.OwnerUserId
    LEFT JOIN AggregatedVotes av ON u.Id = av.UserId
)
SELECT 
    fm.UserId, 
    fm.DisplayName,
    COALESCE(fm.Level, 0) AS UserLevel,
    COALESCE(fm.TotalScore, 0) AS UserScore,
    COALESCE(fm.TotalRecentVotes, 0) AS RecentVotes,
    COALESCE(fm.TotalPositiveVotes, 0) AS PositiveVoteCount
FROM FinalMetrics fm
WHERE fm.TotalScore IS NOT NULL
ORDER BY fm.TotalScore DESC, fm.RecentVotes DESC
LIMIT 10;
