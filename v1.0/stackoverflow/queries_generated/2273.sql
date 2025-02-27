WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    WHERE u.Reputation > 100  -- Considering only reputable users
    GROUP BY u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
        AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName AS UserName,
    u.TotalVotes,
    u.UpVotes,
    u.DownVotes,
    u.AvgPostScore,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.LastEditComment
FROM UserVoteStats u
JOIN PostDetails pd ON u.UserId = pd.OwnerUserId
WHERE u.TotalVotes > 20
AND pd.rn = 1  -- Selecting the most recent post from each user
ORDER BY u.AvgPostScore DESC, u.TotalVotes DESC
LIMIT 50;
