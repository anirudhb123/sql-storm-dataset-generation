WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        1 AS Level
    FROM Users u
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation + 100 AS Reputation,  -- simulate increased reputation
        Level + 1
    FROM Users u
    JOIN UserReputationCTE ur ON u.Id = ur.Id
    WHERE Level < 5  -- limit to 5 levels
),
TagsSummary AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Tags t
    INNER JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY t.TagName
),
PostActivity AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.AcceptedAnswerId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.PostId, ph.CreationDate, ph.Comment
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ur.Level AS ReputationLevel,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgScore,
    pa.Title AS PostTitle,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    cp.CloseCount,
    COALESCE(cp.CloseReason, 'N/A') AS CloseReason
FROM Users u
LEFT JOIN UserReputationCTE ur ON u.Id = ur.Id
LEFT JOIN TagsSummary ts ON ts.PostCount > 10  -- only consider tags with significant posts
LEFT JOIN PostActivity pa ON pa.CommentCount > 0  -- only consider posts with comments
LEFT JOIN ClosedPosts cp ON cp.PostId = pa.Id
WHERE u.Reputation > 100
ORDER BY u.Reputation DESC, ts.PostCount DESC;
