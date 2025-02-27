WITH UserRankings AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        r.Name AS CloseReason
    FROM PostHistory ph
    JOIN CloseReasonTypes r ON ph.Comment::integer = r.Id
    WHERE ph.PostHistoryTypeId = 10
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        CASE 
            WHEN rp.UpVotes - rp.DownVotes > 5 THEN 'Popular'
            ELSE 'Regular'
        END AS PopularityStatus
    FROM RecentPosts rp
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    COALESCE(pp.Title, 'No recent posts') AS RecentPostTitle,
    COALESCE(pp.PopularityStatus, 'N/A') AS PostStatus,
    COALESCE(cp.ClosedDate, NULL) AS PostClosedDate,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason
FROM UserRankings ur
LEFT JOIN PopularPosts pp ON ur.UserId = pp.OwnerUserId
LEFT JOIN ClosedPosts cp ON pp.PostId = cp.PostId
WHERE ur.Reputation > 1000
ORDER BY ur.ReputationRank, pp.UpVotes DESC
LIMIT 100;
