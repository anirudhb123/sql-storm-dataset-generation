WITH UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalVotes DESC) AS Rank
    FROM UserVoteStats
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE((SELECT COUNT(c.Id) 
                  FROM Comments c 
                  WHERE c.PostId = p.Id), 0) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN Tags t ON pt.TagId = t.Id
    GROUP BY p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount
),
PostVotes AS (
    SELECT
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Votes v
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY PostId
),
RecentActivity AS (
    SELECT
        p.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.CreationDate END) AS DeletedDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    GROUP BY p.PostId
)
SELECT
    pu.UserId,
    pu.DisplayName,
    pd.Title,
    pd.CreationDate,
    pd.LastActivityDate,
    pd.Score AS PostScore,
    pd.ViewCount,
    COALESCE(pv.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(pv.TotalDownVotes, 0) AS TotalDownVotes,
    ra.ClosedDate,
    ra.DeletedDate,
    RANK() OVER (PARTITION BY pu.UserId ORDER BY pd.Score DESC) AS PostRank
FROM TopUsers pu
JOIN PostDetails pd ON pu.TotalVotes > 5
LEFT JOIN PostVotes pv ON pd.PostId = pv.PostId
LEFT JOIN RecentActivity ra ON pd.PostId = ra.PostId
WHERE pu.Rank <= 10 
  AND pd.LastActivityDate >= NOW() - INTERVAL '30 days' 
  AND (ra.ClosedDate IS NULL OR ra.DeletedDate IS NULL)
ORDER BY pu.Rank, pd.Score DESC;
