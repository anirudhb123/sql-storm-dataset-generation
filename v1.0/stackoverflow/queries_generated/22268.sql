WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS UserRanking
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 200
    GROUP BY u.Id
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 month'
), CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(CASE WHEN ph.Comment IS NOT NULL THEN ph.Comment END) AS LastCloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed or reopened
    GROUP BY ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.UpVotesCount,
    ua.DownVotesCount,
    uac.PostCount,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViewCount,
    crc.CloseCount AS ClosePostCount,
    crc.LastCloseReason
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.RecentRank = 1
LEFT JOIN CloseReasonCounts crc ON rp.PostId = crc.PostId
WHERE ua.UserRanking <= 10 -- Top 10 active users
ORDER BY ua.Reputation DESC, ua.UpVotesCount DESC
LIMIT 20;

This query analyzes user activity by selecting users with high reputation and their post interactions, while concurrently tracking the most recent post they authored. It also counts how many times their posts have been closed. Results show the top 10 active users, along with specific details about their posts and engagement statistics. This complex query intricately uses CTEs, window functions, and outer joins, providing a deep dive into activity patterns across the Stack Overflow schema.
