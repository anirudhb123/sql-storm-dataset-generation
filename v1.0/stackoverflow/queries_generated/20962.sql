WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS RecentActivityRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        postId,
        MAX(CASE WHEN pht.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        STRING_AGG(CASE WHEN pht.PostHistoryTypeId = 10 THEN pht.Comment END, '; ') AS CloseReasons
    FROM PostHistory pht
    GROUP BY postId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(uv.TotalVotes, 0) AS TotalVotes,
    COALESCE(uv.UpVotes, 0) AS UpVotes,
    COALESCE(uv.DownVotes, 0) AS DownVotes,
    COUNT(DISTINCT rp.PostId) AS RecentPostsCount,
    COUNT(DISTINCT cb.postId) AS ClosedPostsCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    STRING_AGG(DISTINCT cb.CloseReasons, ', ') AS CloseReasons
FROM Users u
LEFT JOIN UserVoteCounts uv ON u.Id = uv.UserId
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN ClosedPosts cb ON rp.PostId = cb.postId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
GROUP BY u.Id, u.DisplayName
HAVING COUNT(DISTINCT rp.PostId) > 0
ORDER BY COUNT(DISTINCT cb.postId) DESC, u.Reputation DESC
LIMIT 10;

In this query:
- We use Common Table Expressions (CTEs) to break down the query into manageable parts: counting user votes, fetching recent posts, determining closed posts and collecting user badge counts.
- We perform a LEFT JOIN to aggregate user-related voting data.
- The recent posts are filtered based on their date, and ranking is applied to the most recent activity per user.
- Closed post details are collected, including reasons for closures, and the results are consolidated into a final selection of users.
- The query includes various aggregates, conditional logic, and complex JOINs to offer an elaborate benchmarking scenario.
