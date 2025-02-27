WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        pd.PostId, 
        pd.OwnerUserId,
        pd.CreationDate,
        pd.NetVotes,
        pd.CloseCount,
        pd.CommentCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM PostDetails pd
    LEFT JOIN UserBadgeStats ub ON pd.OwnerUserId = ub.UserId
    WHERE pd.CommentCount > 0 
      AND pd.CloseCount = 0
),
RankedPosts AS (
    SELECT 
        fp.*, 
        RANK() OVER (ORDER BY fp.NetVotes DESC, fp.CreationDate ASC) AS PostRank
    FROM FilteredPosts fp
)
SELECT 
    r.DisplayName, 
    r.PostId, 
    r.CreationDate, 
    r.NetVotes, 
    r.CommentCount, 
    r.GoldBadges, 
    r.SilverBadges, 
    r.BronzeBadges
FROM RankedPosts r
WHERE r.PostRank <= 10 
ORDER BY r.NetVotes DESC, r.CreationDate DESC;

This query aggregates user badge data, post details, and filters for posts without closes but with comments, applying window functions to rank the posts by net votes, and outputs the top ten results including users' badge counts and details.
