WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
), PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
), PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeOrder
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete
), UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    COALESCE(pbd.BadgeCount, 0) AS BadgeCount,
    COALESCE(phd.UserDisplayName, 'No History') AS LastActivityUser,
    COALESCE(phd.Comment, 'No Comments') AS LastActivityComment,
    CASE 
        WHEN ph.ChangeOrder IS NOT NULL THEN 'Modified' 
        ELSE 'Unmodified' 
    END AS PostStatus
FROM RankedUsers ru
JOIN PopularPosts pp ON ru.Id = pp.OwnerUserId
LEFT JOIN PostHistoryDetails phd ON pp.Id = phd.PostId AND phd.ChangeOrder = 1
LEFT JOIN UserBadgeCounts pbd ON ru.Id = pbd.UserId
WHERE pp.Score > 10 AND pp.ViewCount > 1000
ORDER BY ru.Reputation DESC, pp.Score DESC;
