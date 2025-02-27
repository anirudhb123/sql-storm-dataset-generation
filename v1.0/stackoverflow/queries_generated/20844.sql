WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(COALESCE(DATEDIFF(SECOND, p.CreationDate, COALESCE(p.LastActivityDate, CURRENT_TIMESTAMP)), 0)) AS AvgPostAgeInSeconds
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
),
PostCloseStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT ph.Id) AS CloseCount,
        ARRAY_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY p.Id, p.Title
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.Score > 0 
)
SELECT 
    u.UserId,
    u.DisplayName,
    ups.UpVotes,
    ups.DownVotes,
    ups.TotalPosts,
    ups.AvgPostAgeInSeconds,
    pcs.CloseCount,
    pcs.CloseReasons,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore
FROM UserVoteStats ups
LEFT JOIN PostCloseStats pcs ON pcs.PostId IN (SELECT DISTINCT AcceptedAnswerId FROM Posts WHERE OwnerUserId = ups.UserId)
LEFT JOIN PopularPosts pp ON pp.Rank <= 5
WHERE ups.UpVotes - ups.DownVotes > 0 
AND ups.TotalPosts > 10
ORDER BY ups.UpVotes DESC, ups.DownVotes ASC;
