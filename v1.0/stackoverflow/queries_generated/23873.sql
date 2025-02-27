WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,  
        COUNT(c.Id) AS CommentCount, 
        SUM(v.CreationDate IS NOT NULL) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY p.Id, p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    COALESCE(pp.PostId, -1) AS PostId, 
    pp.CommentCount,
    pp.VoteCount
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN PopularPosts pp ON u.Id = pp.OwnerUserId AND pp.rn = 1
WHERE ur.Reputation IS NOT NULL
ORDER BY ur.Reputation DESC, pp.VoteCount DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

WITH RECURSIVE TagHierarchy AS (
    SELECT 
        Id, 
        TagName, 
        COUNT(*) AS NumPosts 
    FROM Tags
    GROUP BY Id, TagName
    HAVING COUNT(*) > 2
    UNION ALL
    SELECT 
        th.Id, 
        th.TagName, 
        t.NumPosts
    FROM Tags t
    JOIN TagHierarchy th ON t.Id = th.Id 
)
SELECT 
    th.TagName, 
    th.NumPosts 
FROM TagHierarchy th
WHERE th.NumPosts > 5
ORDER BY th.NumPosts DESC;

SELECT DISTINCT
    t.TagName,
    CASE WHEN tp.Id IS NOT NULL THEN 'Has Posts' ELSE 'No Posts' END AS PostStatus
FROM Tags t
LEFT JOIN Posts tp ON t.Id = tp.Id
ORDER BY t.TagName;

SELECT 
    p.Id AS PostId, 
    SUM(CASE WHEN phh.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeletionCount,
    MAX(CASE WHEN phh.PostHistoryTypeId = 11 THEN phh.CreationDate ELSE NULL END) AS LastReopened
FROM Posts p
LEFT JOIN PostHistory phh ON p.Id = phh.PostId
GROUP BY p.Id
HAVING SUM(CASE WHEN phh.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) > 2
ORDER BY p.Id;
