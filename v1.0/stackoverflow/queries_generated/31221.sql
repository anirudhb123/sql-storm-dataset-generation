WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        0 AS Level
    FROM Users u
    WHERE u.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        Level + 1
    FROM Users u
    INNER JOIN RecursiveUserStats r ON u.Id = r.UserId
    WHERE r.Level < 10
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPostCount,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.UpvotedPostCount, 0) AS UpvotedPostCount,
        COALESCE(ps.DownvotedPostCount, 0) AS DownvotedPostCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.LastPostDate, '1900-01-01') AS LastPostDate,
        RANK() OVER (ORDER BY COALESCE(ps.PostCount, 0) DESC, u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE u.CreationDate < (CURRENT_TIMESTAMP - INTERVAL '1 year')
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.UpvotedPostCount,
    u.DownvotedPostCount,
    u.TotalViews,
    u.LastPostDate,
    CASE 
        WHEN u.TotalViews IS NULL OR u.PostCount = 0 THEN 'No Activity'
        WHEN u.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus
FROM AggregatedUserStats u
ORDER BY u.UserRank, u.Reputation DESC
LIMIT 100;

-- Additional query to find active questions with most comments and their last activity
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(c.Id) AS CommentCount,
    p.LastActivityDate,
    p.OwnerDisplayName,
    COALESCE(MAX(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 2), 0) AS Upvotes,
    COALESCE(MAX(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 3), 0) AS Downvotes
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.PostTypeId = 1 AND p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY p.Id, p.Title, p.LastActivityDate, p.OwnerDisplayName
HAVING COUNT(c.Id) > 5
ORDER BY CommentCount DESC, p.LastActivityDate DESC
LIMIT 50;
