WITH RECURSIVE UserHierarchy AS (
    SELECT Id, Reputation, CreationDate, DisplayName, 1 AS Level
    FROM Users
    WHERE Id = (SELECT MIN(Id) FROM Users) -- Assuming root user has the smallest Id

    UNION ALL

    SELECT u.Id, u.Reputation, u.CreationDate, u.DisplayName, uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id > uh.Id
    WHERE u.Reputation > 0
), RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.CreationDate >= '2022-01-01'
    GROUP BY p.Id
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount
    FROM Votes v
    WHERE v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY v.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    uh.Level AS UserLevel,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.Title AS PostTitle,
    rp.Score AS PostScore,
    rp.ViewCount AS PostViews,
    rp.CommentCount AS PostComments,
    rv.VoteCount AS RecentVoteCount
FROM Users u
LEFT JOIN UserHierarchy uh ON u.Id = uh.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN RecentVotes rv ON rp.Id = rv.PostId
WHERE 
    (ub.GoldBadges > 0 OR ub.SilverBadges > 0 OR ub.BronzeBadges > 0)
    AND rp.PostRank = 1
    AND (rv.VoteCount IS NULL OR rv.VoteCount > 5)
ORDER BY u.Reputation DESC, rp.Score DESC;

This query accomplishes several tasks:
1. It builds a recursive CTE (`UserHierarchy`) to create a hierarchy of users based on their Id with a Level.
2. It ranks posts for each user with a window function (`RankedPosts`).
3. It aggregates badges into counts (`UserBadges`).
4. It counts recent votes on posts to find active contributions (`RecentVotes`).
5. Finally, it pulls these together to display users with active contributions and badges, filtering based on certain criteria.

The resulting output provides a comprehensive view of users, their posts, and engagement metrics, making it useful for performance benchmarking by evaluating populated tables and query performance across joins, CTEs, and aggregations.
