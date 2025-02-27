WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId, ph.CreationDate
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(*) AS UsageCount
    FROM Tags t
    JOIN Posts p ON t.Id = p.Id
    GROUP BY TagName
    ORDER BY UsageCount DESC
    LIMIT 5
)
SELECT 
    u.DisplayName,
    u.Location,
    u.Reputation,
    uR.Rank,
    pp.Title AS PopularPost,
    ps.Tags,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    cp.CloseReasons,
    tt.TagName AS TrendingTag
FROM Users u
JOIN UserReputation uR ON u.Id = uR.UserId
LEFT JOIN Posts pp ON pp.OwnerUserId = u.Id 
LEFT JOIN PostVoteSummary vs ON pp.Id = vs.PostId
LEFT JOIN ClosedPosts cp ON pp.Id = cp.PostId
CROSS JOIN TopTags tt
WHERE u.Reputation > 100
ORDER BY u.Reputation DESC, uR.Rank
LIMIT 10;
